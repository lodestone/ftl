module Ftl

  def self.help_message
    %Q{
    Usage: [bold]ftl[/] \[<config-options>\] <command> \[<command-options>\]
      commands: start, kill, list, connect, servers, tags, images, snapshots, volumes
      examples:
        ftl start ninja                    # starts an instance named 'ninja'
        ftl up ninja                       # starts an instance named 'ninja'
        ftl spinup ninja                   # starts an instance named 'ninja'
        ftl launch ninja                   # starts an instance named 'ninja'
        ftl start ninja                    # starts an instance named 'ninja'
        ftl list                           # shows running instances and status
        ftl l                              # shows running instances and status
        ftl connect ninja                  # connects to instance named 'ninja'
        ftl kill ninja                     # kills instances matching name /ninja/
        ftl kill i-123456                  # kills instance with id i-123456
        ftl images                         # shows aws images
        ftl snapshots                      # shows aws snapshots
        ftl tags                           # shows aws tags
        ftl volumes                        # shows aws volumes
        ftl --config=~/ftl.yml servers     # Uses custom config file 
        ftl -c=~/ftl.yml servers           # Uses custom config file 
        ftl --headers=id,tags.Name servers # Uses headers 
        ftl headers servers                # Show possible headers for servers
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
      @con = Fog::Compute.new(:provider => 'AWS', :aws_secret_access_key => options['SECRET_ACCESS_KEY'], :aws_access_key_id => options['ACCESS_KEY_ID'])
      if args && args.length > 0
        arg = args.reverse.pop
        send(arg, args - [arg])
      else
        Ftl.help
      end
    end

    def start(args={})
      if args.first.nil?
        puts "Please provide a short name for instance, like: ftl start ninjaserver"
        return
      end
      display "Spinning up FTL..."
      server = con.servers.create(:user_data         => options[:user_data],
                                  :key_name          => options[:keypair], 
                                  :groups            => options[:groups], 
                                  :image_id          => options[:ami], 
                                  :availability_zone => options[:availability_zone], 
                                  :flavor_id         => options[:instance_type], 
                                  :username          => options[:username]
                                  )
      tag = con.tags.new(:key => "Name", :value => args.first)
      tag.resource_id = server.id
      tag.resource_type = 'instance'
      tag.save
      display server
      eval(options[:post_script]) if options[:post_script]
    end
    alias :up     :start 
    alias :launch :start 
    alias :spinup :start
    alias :create :start
    alias :new    :start

    def connect(args={})
      if match = find_instances(args.first).select{|i| i.state == "running" }.first
        exec("ssh #{options[:username]||'root'}@#{match[:dns_name]}")
      else
        display "Typo alert! No server found!"
      end
    end
    alias :c :connect

    def destroy(args={})
      if args.first.nil?
        puts "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja"
        return
      end
      display "Spinning down FTL..."
      instance = find_instances(args.first)
      instance.map(&:destroy)
    end
    alias :d        :destroy 
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
      tag_match = server_instances.select{|i| !i.tags.nil? && i.tags['Name'] && i.tags['Name'][name] }
      id_match || tag_match
    end

    def _headers_for(object)
      return options[:headers].map(&:to_sym) if options[:headers]
      case object.to_sym
      when :snapshots
        [:id, :volume_id, :state, :volume_size, :description, :"tags.Name"]
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
