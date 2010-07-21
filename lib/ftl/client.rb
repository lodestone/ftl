require 'httparty'
require 'json'

module FTL

  class Client

    include HTTParty

    CONFIG = YAML.load_file(ENV['HOME']+'/.ftl/ftl.yml')
    ACCESS_KEY_ID     = CONFIG['ACCESS_KEY_ID']
    SECRET_ACCESS_KEY = CONFIG['SECRET_ACCESS_KEY']

    base_uri CONFIG['server']
    format :json

    def initialize(args={})
      send(args.reverse!.pop, args)
    end

    def start(args={})
      if args.first.nil?
        puts "Please provide a short name for instance, like: ftl start ninjaserver"
        return
      end
      puts "Spinning up FTL..."
      self.class.post('/machines', :body => '', :query => {:name => args.first, :ami => CONFIG['ami']})
    end

    def connect(args={})
      response = self.class.get('/machines')
      if response.length == 0
        puts "No machines running. try: ftl start <servername>"
      elsif response.length == 1
        server = response.first
      elsif response.length > 1 
        if args.first.nil?
          puts "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja"
        end
        server = response.detect{|r| r['name'][args.first] }
        if server.nil?
          puts "Couldn't find that server name. try: ftl list"
        end
      end
      exec("ssh dev@#{server['dns_name']}") if server['dns_name']
    end

    def destroy(args={})
      if args.first.nil?
        puts "Please provide the name (or partial name for the instance(s) you want to delete. For instance, like: ftl destroy ninja"
        return
      end
      puts "Spinning down FTL..."
      response = self.class.delete('/machines', :query => {:name => args.first}, :body => {:name => args.first})
      puts response['message']
    end

    def list(args={})
      response = self.class.get('/machines')
      column_widths = {'#' => 4}
      if response.blank?
        puts "No machines are running"
        return
      end
      keys          = response.first.keys
      display_keys  = ['#'] + keys
      separator     = ' |'
            
                    
      keys.each {|r|
        widths = [r.length + separator.length]
        widths = widths + response.collect {|pm|
          # WOW right_aws sucks. Why is everything an array. BS
          pm[r].first.length + separator.length
        }
        column_widths[r] = widths.max 
      }

      # Headers
      display_keys.sort.each do |key|
        print key.rjust(column_widths[key])
        print separator 
      end
      print "\n"

      # Machines
      response.each_with_index do |r,idx|
        r['#'] = "#{idx+1}"
        display_keys.sort.each do |key|
          value = r[key].nil? ? '-' : r[key].first
          print value.rjust(column_widths[key])
          print separator
        end
        print "\n"
      end
    end

  end

end

# TODO:
# Server:
#   establish connection
#   read config (what AMI)
#   list available pairing instances
#   start up instance
#   kill instance
#
# Client
#   list available pairing instances (via server call)
#   create new instance
#   connect to new instance
#   destroy instance
