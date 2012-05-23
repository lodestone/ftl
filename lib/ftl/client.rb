module Ftl

  def self.help_message
    %Q{
    Usage: [bold]ftl[/] \[<config-options>\] <command> \[<command-options>\]
      commands: start, kill, list, edit, connect, servers, tags, images, snapshots, volumes
      examples:
        ftl launch ninja                   # Launches an instance named 'ninja'
        ftl list                           # Shows running instances and status
        ftl connect ninja                  # Connects to instance named 'ninja'
        ftl kill ninja                     # Kills instances matching name /ninja/
        ftl kill i-123456                  # Kills instance with id i-123456
        ftl spot ninja 0.02                # Request spot instance using template :ninja for $0.02
        ftl cancel sir-123456              # Cancel spot instance with id sir-123456
        ftl spots                          # Shows AWS spot requests
        ftl images                         # Shows AWS images
        ftl snapshots                      # Shows AWS snapshots
        ftl tags                           # Shows AWS tags
        ftl volumes                        # Shows AWS volumes
        ftl headers servers                # Show possible headers for servers
        ftl headers volumes                # Show possible headers for volumes
        ftl edit                           # Edit ftl.yml with your $EDITOR
        ftl --config=~/ftl.yml servers     # Uses custom config file 
        ftl --headers=id,tags.Name servers # Uses specified headers 
        ftl --version                      # Show version number
    }
  end

  def self.help(*args)
    Formatador.display_line help_message
  end

  class Client

    attr_reader :con
    attr_accessor :options

    def initialize(args=nil, opts={})
      load_config(opts)
      if args && args.length > 0
        arg = args.reverse.pop
        if (arg != 'edit')
          @con = Fog::Compute.new(:provider => 'AWS', :aws_secret_access_key => options['SECRET_ACCESS_KEY'], :aws_access_key_id => options['ACCESS_KEY_ID'])
        end
        send(arg, args - [arg])
      else
        Ftl.help
      end
    end

    def launch(args={})
      if args.first.nil?
        display "Please provide a short name for instance\n\t[bold]ftl[/] launch <name>"
        return
      end
      display "Spinning up FTL..."
      opts = options
      opts = options[:templates][args.first.to_sym] if !options[:templates][args.first.to_sym].nil?
      server = con.servers.create(:user_data          => opts[:user_data],
                                  :key_name           => opts[:keypair], 
                                  :groups             => opts[:groups], 
                                  :image_id           => opts[:ami], 
                                  :availability_zone  => opts[:availability_zone], 
                                  :flavor_id          => opts[:instance_type], 
                                  :username           => opts[:username],
                                  :tags               => opts[:tags].merge(:Name => args.first),
                                  :subnet_id          => opts[:subnet_id],
                                  :private_ip_address => opts[:ip_private],
                                  )
      display server
      eval(options[:post_script]) if options[:post_script]
    end
    alias :up     :launch
    alias :spinup :launch
    alias :create :launch
    alias :new    :launch

    def spot(args={})
      if args.first.nil?
        display "Please provide a short name for instance\n\t[bold]ftl[/] spot <name> <price>"
        return
      end
      if args[1].nil?
        display "Please provide a price for spot request\n\t[bold]ftl[/] spot <name> <price>"
        return
      end
      display "Spinning up FTL..."
      opts = options
      opts = options[:templates][args.first.to_sym] if !options[:templates][args.first.to_sym].nil?
      server = con.spot_requests.create(:user_data         => opts[:user_data],
                                        :price             => args[1],
                                        :key_name          => opts[:keypair], 
                                        :groups            => opts[:groups], 
                                        :image_id          => opts[:ami], 
                                        :availability_zone => opts[:availability_zone], 
                                        :flavor_id         => opts[:instance_type], 
                                        :username          => opts[:username],
                                        :tags              => {:Name => args.first}
                                        )
      display server
    end

    def spots(args={})
      con.spot_requests.table(_headers_for(:spot_requests))
    end

    def cancel(args={})
      if args.first.nil?
        display "Please provide the id for the spot request to cancel."
        return
      end
      spot = con.spot_requests.get(args.first)
      if spot && spot.destroy
        display "Canceled Spot Instance #{spot.id}."
      else
        display "Whups, spot instance not found!"
      end
    end

    def connect(args={})
      if match = find_instances(args.first).select{|i| i.state == "running" }.first
        opt_key = "-i #{options[:keys][match[:key_name]]}" unless (options[:keys].nil? || options[:keys][match[:key_name]].nil?)
        hostname = match[:dns_name] || match[:public_ip_address] || match[:private_ip_address]
        exec("ssh #{opt_key} #{options[:username]||'root'}@#{hostname}")
      else
        display "Typo alert! No server found!"
      end
    end
    alias :x :connect
    alias :ssh :connect

    def status(args={})
      server = find_instance(args.first)
      display server
    end

    def start(args={})
      display "Starting stopped instances is not implemented yet. Stay tuned true believers."
    end

    def stop(args={})
      display "Stopping running instances is not implemented yet. Stay tuned true believers."
    end

    def destroy(args={})
      if args.first.nil?
        display "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja"
        return
      end
      display "Spinning down FTL..."
      instances = find_instances(args.first)
      if instances
        instances.map(&:destroy)
        display "Terminated [bold]\[#{instances.map(&:id).join(', ')}\][/]"
      else
        display "No instances found"
      end
    end
    alias :d        :destroy 
    alias :delete   :destroy 
    alias :kill     :destroy 
    alias :down     :destroy 
    alias :shutdown :destroy 

    def info(args={})
      display find_instance(args.first)
    end
    alias :i :info

    def list(opts)
      opts = [:servers] if opts.empty?
      con.send(opts.first).table(_headers_for(opts.first))
    end
    alias :l :list

    def image(args={})
      Formatador.display_table(con.images.find(:id => args.first))
    end

    # TODO: Make images return only account's images by default
    # def images(args={})
    # end

    def headers(args={})
      display "Showing header options for #{args.first}"
      display con.send(args.first).first.attributes.keys
    end

    def server_instances(args={})
      @servers ||= @con.servers.all
    end

    def edit(args={})
      display "You need to set [bold]$EDITOR[/] environment variable" if ENV['EDITOR'].nil?
      `$EDITOR ~/.ftl/ftl.yml`
    end


    ###########################################################################
    ## private                                                              ###
    ###########################################################################
    private

    def ftl_yml
      File.open("lib/resources/ftl.yml").read
    end

    def load_config(opts={})
      # TODO Make this less shitty. Such a common pattern.
      if opts[:config]
        default_config_file = opts[:config]
      else
        default_config_name = 'ftl.yml'
        default_config_dir  = '/.ftl/'
        default_config_home = "#{ENV['HOME']}#{default_config_dir}"
        default_config_file = "#{default_config_home}#{default_config_name}"
        if Dir.exist?(default_config_home) # Directory exists 
          if !File.exist?(default_config_file) # File does not
            File.open(default_config_file, 'w') {|f| f << ftl_yml }
          end
        else # Directory does not exist 
          Dir.mkdir(default_config_home)
          File.open(default_config_file, 'w') {|f| f << ftl_yml }
        end
      end
      @options = YAML.load_file(default_config_file)
      @options = @options.merge(opts)
      puts "======Please open #{default_config_file} and set ACCESS_KEY_ID and SECRET_ACCESS_KEY====\n\n" if aws_credentials_absent?
    end

    def find_instance(name)
      find_instances(name).first
    end

    def find_instances(name)
      id_match  = server_instances.select{|i| i[:id] == name } if name[/^i-/]
      exact_tag_match = server_instances.select{|i| !i.tags.nil? && i.tags['Name'] && i.tags['Name'] == name }
      tag_match = server_instances.select{|i| !i.tags.nil? && i.tags['Name'] && i.tags['Name'][name] }
      id_match || exact_tag_match || tag_match
    end

    def _headers_for(object)
      return options[:headers].map(&:to_sym) if options[:headers]
      case object.to_sym
      when :snapshots
        [:id, :volume_id, :state, :volume_size, :description, :"tags.Name"]
      when :spot_requests
        [:id, :image_id, :availability_zone, :price, :flavor_id, :state, :request_type, :launched, :created_at]
      when :volumes
        [:server_id, :id, :size, :snapshot_id, :availability_zone, :state, :"tags.Name"]
      when nil
        [:id, :image_id, :flavor_id, :availability_zone, :state, :"tags.Name"]
      else
        [:id, :image_id, :flavor_id, :availability_zone, :state, :"tags.Name"]
      end
    end

    def aws_credentials_absent?
      options['ACCESS_KEY_ID'].nil? || options['SECRET_ACCESS_KEY'].nil?
    end

    def display(message)
      msg = message.is_a?(String) ? message : message.inspect
      Formatador.display_line(msg)
    end

    def method_missing(*args)
      begin
        method = args.first
        # opts = args[1]
        if con.respond_to? method
          display con.send(method).table(_headers_for(method))
        else
          Ftl.help
        end
      rescue 
      end
    end

  end

end
