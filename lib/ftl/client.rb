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
        ftl images                         # Show AMIs associated with your account
        ftl <action> ninja                 # Execute the <action> (specified in ftl.yml) on the remote server instance
        ftl <script> ninja                 # Execute the <script> (specified in ftl.yml) on your local machine
        ftl --config=~/ftl.yml servers     # Uses custom config file
        ftl --headers=id,tags.Name servers # Uses specified headers
        ftl --version                      # Show version number
    }
  end

  def self.help(*args)
    Formatador.display_line help_message
  end

  class Client

    SINGLE_COMMANDS = %w{ edit sample }

    attr_reader :con
    attr_accessor :options

    def initialize(args=nil, opts={})
      if args && args.length > 0
        arg = args.reverse.pop
        @args = [arg, args - [arg]]
        load_config(opts)
        if (!SINGLE_COMMANDS.include?(arg))
          @con = Fog::Compute.new(:provider => 'AWS', :aws_secret_access_key => options['SECRET_ACCESS_KEY'], :aws_access_key_id => options['ACCESS_KEY_ID'])
        end
        send(*@args)
      else
        Ftl.help
      end
    end

    def launch_instance(args)
      display "Spinning up FTL..."
      opts = options
      opts = options.merge(options[:templates][args.first.to_sym]) if !options[:templates][args.first.to_sym].nil?

      opts[:group_ids] = (opts[:group_ids] || []) + opts[:groups].select { | group | group.to_s =~ /^sg-[0-9a-f]{8}$/ }
      opts[:groups] = opts[:groups].reject { | group | group.to_s =~ /^sg-[0-9a-f]{8}$/ }

      launcher = options.delete(:launcher) || :servers
      server = con.send(launcher).create(
                                  :user_data          => opts[:user_data],
                                  :key_name           => opts[:keypair],
                                  :groups             => opts[:groups],
                                  :security_group_ids => opts[:group_ids],
                                  :image_id           => opts[:ami],
                                  :availability_zone  => opts[:availability_zone],
                                  :flavor_id          => opts[:instance_type],
                                  :username           => opts[:username],
                                  :tags               => opts[:tags].merge(:Name => args.first),
                                  :subnet_id          => opts[:subnet_id],
                                  :private_ip_address => opts[:ip_private],
                                  :ip_address         => opts[:ip_address],
                                  :price              => opts[:price],
                                  :instance_count     => opts[:count]
                                 )

      display server
      display "Executing :post_script..." if opts[:post_script]
      eval(opts[:post_script]) if opts[:post_script]
    end

    def launch(args={})
      guard(args.first, "Please provide a short name for instance\n\t[bold]ftl[/] launch <name>")
      options.merge(options[:templates][args.first.to_sym]) if !options[:templates][args.first.to_sym].nil?
      server = launch_instance(args)
    end
    alias :up     :launch
    alias :spinup :launch
    alias :create :launch
    alias :new    :launch

    def spot(args={})
      guard(args[0], "Please provide a short name for instance\n\t[bold]ftl[/] spot <name> <price>")
      guard(args[1], "Please provide a price for spot request\n\t[bold]ftl[/] spot <name> <price>")
      display "Spinning up FTL..."
      options.merge(options[:templates][args.first.to_sym]) if !options[:templates][args.first.to_sym].nil?
      options[:price] = args[1] || options[:templates][args.first.to_sym][:price] || options[:price]
      options.merge!(:launcher => :spot_requests)
      server = launch_instance(args)
    end
    alias :request :spot

    def spots(args={})
      con.spot_requests.table(_headers_for(:spot_requests))
    end
    alias :spot_requests :spots

    def cancel(args={})
      guard(args.first, "Please provide the id for the spot request to cancel.") 
      spot = con.spot_requests.get(args.first)
      if spot && spot.destroy
        display "Canceled Spot Instance #{spot.id}."
      else
        display "Whups, spot instance not found!"
      end
    end

    def running_instances(name)
      find_instances(name).select{|i| i.state == "running" }
    end

    def running_instance(name)
      instances = running_instances(name)
      instances.first if instances
    end

    def connect(args={})
      if server = running_instance(args.first)
        # puts(ssh_command(server))
        exec(ssh_command(server))
      else
        display "Typo alert! No server found!"
      end
    end
    alias :x :connect
    alias :ssh :connect

    def status(args={})
      guard(args, :message => "Please provide the name/id of a server (ftl status <server>)")
      server = find_instance(args.first)
      display server
    end
    alias :st :status

    def start(args={})
      display "Bringing \"#{args.first}\" server back to life."
      find_instance(args.first).start
    end
    alias :run :start

    def stop(args={})
      display "Stopping \"#{args.first}\" server."
      find_instance(args.first).stop
    end
    alias :pause :stop

    def destroy(args={})
      guard(on_what, "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja")
      display "Spinning down FTL..."
      instances = find_instances(on_what).select{|i| i.state == 'running' }
      if !instances.empty?
        instances.map(&:destroy)
        display "Destroyed [bold]\[#{instances.map(&:id).join(', ')}\][/]"
      else
        display "No instances found"
      end
    end
    alias :d         :destroy
    alias :delete    :destroy
    alias :kill      :destroy
    alias :down      :destroy
    alias :shutdown  :destroy

    def terminate(args={})
      guard(on_what, "Please provide the name (or partial name for the instance(s) you want to terminate. For instance, like: ftl destroy ninja")
      display "Spinning down FTL..."
      instances = find_instances(on_what)
      if !instances.empty?
        instances.map(&:destroy)
        display "Destroyed [bold]\[#{instances.map(&:id).join(', ')}\][/]"
      else
        display "No instances found"
      end
    end
    alias :t :terminate

    def info(args={})
      display find_instance(args.first)
    end
    alias :i :info

    def list(opts)
      opts = [:servers] if opts.empty?
      con.send(opts.first).table(_headers_for(opts.first))
    end
    alias :l  :list
    alias :ls :list

    def image(args={})
      Formatador.display_table(con.images.find(:id => args.first))
    end
    alias :img :image

    # TODO: Make this better by including more details of block devices
    def images(args={})
      hashes = con.describe_images('Owner' => 'self').body['imagesSet'].collect do |hash|
        h = {}
        h[:image_id]  = hash['imageId']
        h[:name]  = hash['name']
        h[:rootDeviceType] = hash['rootDeviceType']
        h
      end 
      puts Formatador.display_table(hashes)
    end
    alias :describe_images :images

    def ip_addresses
      con.addresses
    end

    def ips(args={})
      # TODO add server "name"
      addrs = con.describe_addresses.body['addressesSet'] #.collect do |addr|
        # addr
      # end 
      Formatador.display_table addrs
    end
    alias :addresses :ips

    def headers(args={})
      what = args.first || :servers
      display "Showing header options for #{what}"
      display con.send(what).first.attributes.keys
    end

    def server_instances(args={})
      @servers ||= (con.servers.all||[])
    end

    def edit(args={})
      display "You need to set [bold]$EDITOR[/] environment variable" if ENV['EDITOR'].nil?
      `$EDITOR ~/.ftl/ftl.yml`
    end

    def sample(args={})
      puts File.open(File.dirname(__FILE__) + "/../resources/ftl.yml").read
    end

    def command
      @args[0]
    end

    def secondary_arguments
      @args[1] 
    end

    def on_what 
      secondary_arguments.first
    end

    def volume(args={})
      arg = args.is_a?(String) ? args : on_what
      display vol = con.volumes.select{|v| v.tags['Name'] == arg || v.id == arg }.first
      vol
    end

    def execute(args={})
      arg = args.is_a?(String) ? args : args[1]
      server = find_instances(on_what).select{|i| i.state == 'running' }.first
      puts %|#{ssh_command(server)} #{arg}|
      system(%|#{ssh_command(server)} #{arg}|)
    end
    alias :ex :execute

    ###########################################################################
    ## private                                                              ###
    ###########################################################################
    private
 
    def ssh_command(server)
      opt_key = " -i #{options[:keys][server[:key_name]]}" unless (options[:keys].nil? || options[:keys][server[:key_name]].nil?)
      hostname = server[:public_ip_address] || server[:dns_name] || server[:private_ip_address]
      server_name =  server.tags['Name'].to_sym
      user_name = options[:templates][server_name][:username] 
      user_name = 'root' if user_name.nil? || user_name.length == 0
      "ssh#{opt_key} #{user_name}@#{hostname}"
    end

    def guard(arg, options={:message => "Please refer to ftl help"})
      if arg.nil?
        display options[:message]
        exit
      end
    end
 
    def ftl_yml
      File.open("lib/resources/ftl.yml").read
    end

    def load_config(opts={})
      # TODO So ugly, make this less shitty. Such a common pattern.
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
      case object
      when :snapshots
        [:id, :volume_id, :state, :volume_size, :description, :"tags.Name"]
      when :spot_requests
        [:id, :image_id, :availability_zone, :price, :flavor_id, :state, :request_type, :launched, :created_at]
      when :volumes
        [:server_id, :id, :size, :snapshot_id, :availability_zone, :state, :"tags.Name"]
      when nil
        [:id, :image_id, :flavor_id, :availability_zone, :state, :created_at, :"tags.Name"]
      else
        [:id, :image_id, :flavor_id, :availability_zone, :state, :created_at, :"tags.Name"]
      end
    end

    def aws_credentials_absent?
      options['ACCESS_KEY_ID'].nil? || options['SECRET_ACCESS_KEY'].nil?
    end

    def display(message)
      msg = message.is_a?(String) ? message : message.inspect
      Formatador.display_line(msg)
    end

    def eval_action(script, args)
      # TODO Complete the script to handle multiple servers, like:
      # ftl bundle server1 server2 server3
      # server = find_instance(on_what)
      server = find_instances(on_what).select{|i| i.state == 'running' }.first
      eval(script, binding)
    end

    def eval_script(script, args)
      eval(script, binding)
    end

    def local(cmd)
      puts output = %x|#{cmd}|
      output
    end

    # def remote(cmd)
    #   %x|#{ssh_command(server)} #{cmd}|
    # end

    def method_missing(*args)
      method = args.first.to_sym
      if con.respond_to? method
        results = con.send(method)
        display results.table(_headers_for(method))
      elsif options[:actions][method]
        eval_action(options[:actions][method], args)
      elsif options[:scripts][method]
        eval_script(options[:scripts][method], args)
      else
        Ftl.help
      end
    end

  end

end
