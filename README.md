# Ftl

Faster Than Light. Fog Terminal Language. For Terminal Launching.

## Description

Ftl is an AWS (fog) based application for managing cloud instances from the command line.

## Installation

Install is easy.

    $ gem install ftl # or sudo gem install ftl

## Usage

### Example commands

    Usage: ftl [<config-options>] <command> [<command-options>]
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
          ftl kill ninja                     # kills instance Named "ninja"
          ftl kill i-123456                  # kills instance with id i-123456
          ftl images                         # shows aws images
          ftl snapshots                      # shows aws snapshots
          ftl tags                           # shows aws tags
          ftl volumes                        # shows aws volumes
          ftl --config=~/ftl.yml servers     # Uses custom config file 
          ftl -c=~/ftl.yml servers           # Uses custom config file 
          ftl --headers=id,tags.Name servers # Uses headers 
          ftl headers servers                # Show possible headers for servers

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
