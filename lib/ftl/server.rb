require 'sinatra'
require 'right_aws'
require 'sdb/active_sdb'
require 'json'
# require 'fog'
# ENV["FOG_RC"] = Will need this if we switch to Fog

class PairingMachine < Aws::ActiveSdb::Base
end

module FTL

  class Server < Sinatra::Base

    ACCESS_KEY_ID     = ENV['ACCESS_KEY_ID']     || YAML.load_file(ENV['HOME']+'/.ftl/ftl.yml')['ACCESS_KEY_ID']
    SECRET_ACCESS_KEY = ENV['SECRET_ACCESS_KEY'] || YAML.load_file(ENV['HOME']+'/.ftl/ftl.yml')['SECRET_ACCESS_KEY']

    before do
      Aws::ActiveSdb.establish_connection(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
    end

    get '/machines' do
      # List the machines
      pms = PairingMachine.find(:all)
      ec2 = Aws::Ec2.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
      pms.each do |pm|
        i = ec2.describe_instances(pm.attributes['aws_instance_id'])[0]
        pm[:dns_name] = i[:dns_name]
        pm.save
      end
      pms.collect{|pm| pm.attributes }.to_json
    end

    post '/machines' do
      # Create new machine
      return "Need to name this machine" unless params[:name]
      return "Please provide an ami" unless params[:ami]
      pm = PairingMachine.new(params)
      pm[:instance_type] ||= 'm1.small'
      ec2 = Aws::Ec2.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
      i = ec2.launch_instances(params[:ami], :user_data => "#!/", :instance_type => pm[:instance_type])[0]
      pm[:aws_instance_id] = i[:aws_instance_id]
      pm[:dns_name] = i[:dns_name]
      pm.save
      pm.attributes.to_json
    end

    delete '/machines' do
      # Destroy the machine by short name
      pms = PairingMachine.find(:all)
      pms = pms.select{|pm| pm.attributes['name'].first[params['name']] }
      return "{message: \"Provide the name of the machine(s) to be terminated\"}" if params['name'].nil? || pms.blank?
      ec2 = Aws::Ec2.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
      instances = pms.collect{|pm| pm.attributes['aws_instance_id'].first }
      ec2.terminate_instances(instances)
      pms.each {|pm|
        pm.delete 
      }
      "{message: \"Shutdown machines matching '#{params['name']}'\"}"
    end

  end

end

