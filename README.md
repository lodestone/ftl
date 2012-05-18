# Ftl

Faster Than Light. Fog Terminal Language. For Terminal Launching.

## Description

Ftl is an AWS (fog-based) application for managing cloud instances from the command line.
Easier than chef or the ec2 command line tools. Smarter too.

## Installation

Install is easy.

    $ gem install ftl # or sudo gem install ftl

## Usage

### Example commands

    Usage: ftl [<config-options>] <command> [<command-options>]
      commands: start, kill, list, edit, connect, servers, tags, images, snapshots, volumes
      examples:
        ftl launch ninja                   # Launches an instance named 'ninja'
        ftl list                           # Shows running instances and status
        ftl connect ninja                  # Connects to instance named 'ninja'
        ftl kill ninja                     # Kills instances matching name /ninja/
        ftl kill i-123456                  # Kills instance with id i-123456
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

© 2012 Matthew Petty Twitter:@mattpetty Github:@lodestone Email:lodestone@gmail.com