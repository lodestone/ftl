module Ftl

  def self.help_message
    %Q{
Usage: ftl [<config-options>] <command> [<command-options>]
  commands: start, kill, list, connect, servers, tags, images, snapshots, volumes
  examples:
    ftl start ninja                    # starts an instance named 'ninja'
    ftl list                           # shows running instances and status
    ftl connect                        # connects to instance if only one is running
    ftl connect ninja                  # connects to instance named 'ninja'
    ftl kill nin                       # kills all instances matching /nin/
    ftl images                         # shows aws images
    ftl snapshots                      # shows aws snapshots
    ftl tags                           # shows aws tags
    ftl volumes                        # shows aws volumes
    ftl --config=~/ftl.yml servers     # Uses custom config file 
    ftl -c=~/ftl.yml servers           # Uses custom config file 
    ftl --headers=id,tags.Name servers # Uses headers 
    ftl servers headers                # Show possible headers
    }
  end

  def self.help(*args)
    puts help_message
  end

  class Client

    attr_reader :con
    attr_accessor :options

    def initialize(args=nil, opts={})
      load_config(opts)
      @con = Fog::Compute.new(:provider => 'AWS', :aws_secret_access_key => options['SECRET_ACCESS_KEY'], :aws_access_key_id => options['ACCESS_KEY_ID'])
      if args
        arg = args.reverse.pop
        send(arg, args - [arg])
      end
    end

   def ftl_yml
%Q%
ACCESS_KEY_ID: 
SECRET_ACCESS_KEY: 
:ami: ami-a29943cb
:instance_type: c1.medium
:default_username: ubuntu
:instance_script:
  #!/bin/sh
  touch file.touched
:spinup_script:
  class Samurai;
    def slice!;
      puts "slice";
    end;
  end;
  Samurai.new.slice!

%
   end

   def load_config(opts={})
     # TODO Make this less shitty. Such a common pattern.
     default_config_name = 'ftl.yml'
     default_config_dir  = '/.ftl/'
     default_config_home = "#{ENV['HOME']}#{default_config_dir}"
     default_config_file = "#{default_config_home}#{default_config_name}"
     if Dir.exist?(default_config_home) 
       if !File.exist?(default_config_file)     
         File.open(default_config_file, 'w') {|f| f << ftl_yml }
       end
     else
       Dir.mkdir(default_config_home)
       File.open(default_config_file, 'w') {|f| f << ftl_yml }
     end
     @options = YAML.load_file(default_config_file)
     @options = @options.merge(opts)
     puts "======Please open #{default_config_file} and set ACCESS_KEY_ID and SECRET_ACCESS_KEY====\n\n" if aws_credentials_absent?
   end

   def aws_credentials_absent?
     options['ACCESS_KEY_ID'].nil? || options['SECRET_ACCESS_KEY'].nil?
   end







    def start(args={})

      if INSTANCE_SCRIPT.nil?
        # instance_script = '#!' 
      else
        # instance_script = INSTANCE_SCRIPT[/^#!/] ? INSTANCE_SCRIPT : URI.parse(INSTANCE_SCRIPT).read
      end

      if args.first.nil?
        puts "Please provide a short name for instance, like: ftl start ninjaserver"
        return
      end
      puts "Spinning up FTL..."
      i = @aws.launch_instances(options[:ami], :key_name => options[:key_name], :tags => {"Name" => args.first}, :user_data => options[:instance_script], :instance_type => options[:instance_type])
      i = con.servers.new()
      p i[:id]
      
      # aws.create_tags(i.first[:], {"Name" => "my_awesome_server"})
    end
    alias :up     :start 
    alias :spinup :start
    alias :create :start
    alias :new    :start

    def connect(args={})
      # Do some monkeying with .ssh/known_hosts to clear ones we've seen before
      match = server_instances.find{|instance| instance[:tags]['Name'] == args.first || instance[:id] == args.first }
      if match
        exec("ssh #{CONFIG[:default_username]||'root'}@#{match[:dns_name]}")
      else
        puts "Typo alert! No server found!"
      end
    end
    alias :c :connect

    def destroy(args={})
      if args.first.nil?
        puts "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja"
        return
      end
      puts "Spinning down FTL..."
      @aws.terminate_instances(args.first)
    end
    alias :kill     :destroy 
    alias :down     :destroy 
    alias :shutdown :destroy 


    # ftl info <instance-id|tag.name>
    def info(args={})
      p @con.servers.get(args.first)
    end

    # ftl list
    # ftl list /regex/ 
    def list(args={})
      # Formatador.display_table(servers, headers)
      server_instances.table(options[:headers]||headers)
    end

    def image(args={})
      Formatador.display_table(@con.images.find(:id => args.first))
    end

    def method_missing(*args)
      begin
        method = args.first
        options = args[1]
        if @con.respond_to? method
          case options.first
          when 'headers'
            print method
            p @con.send(method).first.attributes.keys
          else
            p @con.send(method).table(headers(method))
          end
        else
          Ftl.help
          # super(*args)
        end
      rescue 
        Ftl.help
        # super(*args)
      end
    end

    def headers(type=nil)
      return options[:headers].map(&:to_sym) if options[:headers]
      case type
      when :snapshots
        [:id, :volume_id, :state, :volume_size, :description, :"tags.Name"]
      when :volumes
        [:server_id, :id, :size, :snapshot_id, :availability_zone, :state, :"tags.Name"]
      else
        [:id, :image_id, :flavor_id, :availability_zone, :state, :"tags.Name"]
      end
    end

    def extract_headers
      # POSSIBLE HEADERS:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      # ami_launch_index | architecture | aws_availability_zone | aws_image_id 
      # aws_instance_id | aws_instance_type | aws_kernel_id | aws_launch_time
      # aws_owner | aws_product_codes | aws_reason | aws_reservation_id 
      # aws_state | aws_state_code | block_device_mappings | client_token 
      # dns_name | groups | hypervisor | ip_address | monitoring_state  
      # placement_tenancy | private_dns_name | private_ip_address | requester_id 
      # root_device_name | root_device_type | ssh_key_name | state_reason_code 
      # state_reason_message | tags | virtualization_type
      # ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      # p args
      # Fog::AWS::
      # RightAWS
      @extract_headers ||= [:id, :image_id, :flavor_id, :availability_zone, :state, :tags]
    end

    def server_instances(args={})
      # @aws.describe_instances
      # vs
      # @servers ||= @con.servers.map {|s| extract_headers.inject({}) {|hash, header| hash[header] = s[header]; hash }}
      # What a hack. 
      @servers ||= @con.servers.all
      # Less of a hack
    end

  private


end



end
