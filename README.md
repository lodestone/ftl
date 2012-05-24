# Ftl

Faster Than Light. Fog Terminal Language. For Terminal Launching.

## Description

`ftl` is an AWS (fog-based) application for managing cloud instances from the command line.
Easier than chef or the ec2 command line tools. Smarter too.

## Installation

Install is easy.

    $ gem install ftl # or sudo gem install ftl

## Usage

    Usage: ftl [<config-options>] <command> [<command-options>]
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

## Getting started

`ftl` depends on a configuration file. When you run it for the first time,
it will create a simple configuration file at `~/.ftl/ftl.yml`. Note that the starter file is incomplete;
you will need to supply at least your Amazon AWS security credentials. You can open the
configuration file in the editor named by the `$EDITOR` environment variable by running `ftl edit`.

### Configuration file

In addition to the AWS security credentials, the configuration file contains parameters for
launching instances and connecting to them.

    ACCESS_KEY_ID:      # Amazon AWS access key
    SECRET_ACCESS_KEY:  # Amazon AWS secret access key

    :keys:
      ninja-keypair:        ~/.ec2/id_rsa-ninja-keypair

    :templates:
      :ninja:
        :ami:               ami-a29943cb  # Ubuntu 12.04 LTS Precise Pangolin
        :username:          ubuntu
        :keypair:           ninja-keypair
        :instance_type:     m1.small
        :tags:              {}
        :groups:
          - default
          - apache
          - postgresql

#### The :templates section

`:templates` is a hash of server names and the EC2 parameters used to launch them.

* :ami -- the ID of the AMI to use
* :availability_zone -- the availability zone into which the instance should be launched
* :groups -- a list of names and/or IDs of security groups to assign to the instance
* :instance_type -- the name of the EC2 instance size (e.g. 'm1.small')
* :ip_private -- the private IP address to assign to the instance (optional)
* :ip_public -- the public IP address to assign to the instance (optional)
* :keypair -- the name of the keypair installed in the instance when launched; this is important
              for connecting to the instance once it has been launched
* :subnet_id -- the ID of the subnet into which the instance should be launched (optional)
* :tags -- a hash of tags to be set on the instance; 'Name' will be automatically set from the
           server name
* :username -- the username to use when connecting to the instance

#### A note on security groups

Security groups defined in a virtual private cloud (VPC) can be specified only by ID.

#### The :keys section

`:keys`, if defined, is a hash of keypair names and the names of files on the local filesystem
containing them. If there is an entry in `:keys` with the same name as the server, the file will be
passed in the `-i` option to `ssh` when connecting.

### Launching an instance

Once a server has been configured, it can be launched by name.

    ftl launch ninja

To connect to it, run `ftl connect ninja`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

© 2012 Matthew Petty 

* Twitter: [@mattpetty](http://twitter.com/mattpetty) 
* Github: [@lodestone](http://github.com/lodestone) 
* Email: [lodestone@gmail.com](mailto:lodestone@gmail.com)