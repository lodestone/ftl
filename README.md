# Ftl

Faster Than Light. Fog Terminal Language. For Terminal Launching.

## Installation

Add this line to your application's Gemfile:

    gem 'ftl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ftl

## Usage

### Example commands

    Usage: ftl [<config-options>] <command> [<command-options>]
      commands: start, kill, list, connect, servers, tags, images, snapshots, volumes
      examples:
        ftl start ninja                    # starts an instance named 'ninja'
        ftl list                           # shows running instances and status
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
