require 'fog/compute/models/server'
class Fog::Compute::AWS
  class Server < Fog::Compute::Server
    def [](m)
      send(m)
    end
  end
end
