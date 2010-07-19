require 'sinatra'
require 'right_aws'
# require 'fog'
require 'sdb/active_sdb'
require 'json'
# ENV["FOG_RC"] = 

class PairingMachine < Aws::ActiveSdb::Base
end

module FTL

  class Server < Sinatra::Base

    ACCESS_KEY_ID     = ENV['ACCESS_KEY_ID']
    SECRET_ACCESS_KEY = ENV['SECRET_ACCESS_KEY']

    before do
      Aws::ActiveSdb.establish_connection(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
    end

    get '/machines' do
      # List the machines
      p pms = PairingMachine.find(:all)

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
      pm = PairingMachine.new(params)
      ec2 = Aws::Ec2.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
      i = ec2.launch_instances(params[:ami])[0]
      pm[:aws_instance_id] = i[:aws_instance_id]
      pm[:dns_name] = i[:dns_name]
      pm.save
      pm.attributes.to_json
    end

    delete '/machines' do

      p params
      # Destroy the machine by short name
      pms = PairingMachine.find(:all)
      p pms
      pms = pms.select{|pm| pm.attributes['name'].first[params['name']] }
      return "{message: \"Provide the name of the machine(s) to be terminated\"}" if params['name'].nil? || pms.blank?
      ec2 = Aws::Ec2.new(ACCESS_KEY_ID, SECRET_ACCESS_KEY)
      instances = pms.collect{|pm| pm.attributes['aws_instance_id'].first }
      p instances
      p ec2.terminate_instances(instances)
      pms.each {|pm|
        puts "going to delete pm: #{pm.inspect}"
        pm.delete 
      }
      "{message: \"Shutdown machines matching '#{params['name']}'\"}"
    end

  end

end

