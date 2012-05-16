module Ftl

  class Client

    CONFIG            = YAML.load_file(ENV['HOME']+'/.ftl/ftl.yml')
    ACCESS_KEY_ID     = CONFIG['ACCESS_KEY_ID']
    SECRET_ACCESS_KEY = CONFIG['SECRET_ACCESS_KEY']
    SPINUP_SCRIPT     = CONFIG['spinup_script']
    INSTANCE_SCRIPT   = CONFIG['instance_script']
    AMI               = CONFIG['ami']
    INSTANCE_TYPE     = CONFIG['instance_type']
    KEY_NAME          = CONFIG['key_name']

    attr_accessor :con

    def initialize(args=nil)
      @con = Fog::Compute.new(:provider => 'AWS', :aws_secret_access_key => SECRET_ACCESS_KEY, :aws_access_key_id => ACCESS_KEY_ID)
      if args
        arg = args.reverse.pop
        send(arg, args - [arg])
      end
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
      i = @aws.launch_instances(AMI, :key_name => KEY_NAME, :tags => {"Name" => args.first}, :user_data => INSTANCE_SCRIPT, :instance_type => INSTANCE_TYPE)
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
      server_instances.table(headers)
    end

    def image(args={})
      Formatador.display_table(@con.images.find(:id => args.first))
    end

    def help(*args)
      puts "Usage: ftl <command> <options>"
      puts "  commands: start kill list connect"
      puts "  examples:"
      puts "    ftl start ninja   # starts an instance named 'ninja'"
      puts "    ftl list          # shows running instances and status"
      puts "    ftl connect       # connects to instance if only one is running"
      puts "    ftl connect ninja # connects to instance named 'ninja'"
      puts "    ftl kill nin      # kills all instances matching /nin/"
      puts "    ftl images        # shows aws images"
      puts "    ftl snapshots     # shows aws snapshots"
      puts "    ftl tags          # shows aws tags"
      puts "    ftl volumes       # shows aws volumes"
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
          when /^headers=/
            headerz = options.first.gsub("headers=",'').split(',')
            p @con.send(method).table(headerz)
          else
            p @con.send(method).table(headers(method))
          end
        else
          help
          super(*args)
        end
      rescue 
        help
        super(*args)
      end
    end

    def headers(type=nil)
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
  
  def default_user_script
  end

end



end
