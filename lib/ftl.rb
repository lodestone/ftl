require 'sinatra'

# Amazon credentials for Mobilecause
ACCESS_KEY_ID     = 'AKIAJHSAGBXSKRR4EHOA'
SECRET_ACCESS_KEY = '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'

@ec2 = AWS::EC2::Base.new(:access_key_id => ACCESS_KEY_ID, :secret_access_key => SECRET_ACCESS_KEY)

# This is how to make a rack app, just call it config.ru and push to heroku
# run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello World!\n")] }

class Ftl < Sinatra::Base

  get '/' do
    "Hello World!"
  end

end

