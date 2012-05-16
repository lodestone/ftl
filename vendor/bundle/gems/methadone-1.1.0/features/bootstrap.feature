Feature: Bootstrap a new command-line app
  As an awesome developer who wants to make a command-line app
  I should be able to use methadone to bootstrap it
  And get all kinds of cool things

  Background:
    Given the directory "tmp/newgem" does not exist

  Scenario: Bootstrap a new app from scratch
    When I successfully run `methadone tmp/newgem`
    Then the following directories should exist:
      |tmp/newgem                           |
      |tmp/newgem/bin                       |
      |tmp/newgem/lib                       |
      |tmp/newgem/lib/newgem                |
      |tmp/newgem/test                      |
      |tmp/newgem/features                  |
      |tmp/newgem/features/support          |
      |tmp/newgem/features/step_definitions |
    Then the following directories should not exist:
      |tmp/newgem/spec |
    And the following files should exist:
      |tmp/newgem/newgem.gemspec                            |
      |tmp/newgem/Rakefile                                  |
      |tmp/newgem/.gitignore                                |
      |tmp/newgem/Gemfile                                   |
      |tmp/newgem/bin/newgem                                |
      |tmp/newgem/features/newgem.feature                   |
      |tmp/newgem/features/support/env.rb                   |
      |tmp/newgem/features/step_definitions/newgem_steps.rb |
      |tmp/newgem/test/tc_something.rb                      |
    And the file "tmp/newgem/.gitignore" should match /results.html/
    And the file "tmp/newgem/.gitignore" should match /html/
    And the file "tmp/newgem/.gitignore" should match /pkg/
    And the file "tmp/newgem/.gitignore" should match /.DS_Store/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('aruba'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('rdoc'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_development_dependency\('rake','~> 0.9.2'/
    And the file "tmp/newgem/newgem.gemspec" should match /add_dependency\('methadone'/
    And the file "tmp/newgem/newgem.gemspec" should use the same block variable throughout
    Given I cd to "tmp/newgem"
    And my app's name is "newgem"
    When I successfully run `bin/newgem --help` with "lib" in the library path
    Then the banner should be present
    And the banner should document that this app takes options
    And the following options should be documented:
      |--version|
      |--log-level|
    And the banner should document that this app takes no arguments
    When I successfully run `rake -T -I../../lib`
    Then the output should contain:
    """
    rake build         # Build newgem-0.0.1.gem into the pkg directory
    rake clean         # Remove any temporary products.
    rake clobber       # Remove any generated file.
    rake clobber_rdoc  # Remove RDoc HTML files
    rake features      # Run Cucumber features
    rake install       # Build and install newgem-0.0.1.gem into system gems
    rake rdoc          # Build RDoc HTML files
    rake release       # Create tag v0.0.1 and build and push newgem-0.0.1.gem to Rubygems
    rake rerdoc        # Rebuild RDoc HTML files
    rake test          # Run tests
    """    
    When I run `rake -I../../../../lib`
    Then the exit status should be 0
    And the output should match /1 tests, 1 assertions, 0 failures, 0 errors/
    And the output should contain:
    """
    1 scenario (1 passed)
    6 steps (6 passed)
    """

  Scenario: Won't squash an existing dir
    When I successfully run `methadone tmp/newgem`
    And I run `methadone tmp/newgem`
    Then the exit status should not be 0
    And the stderr should contain:
    """
    error: tmp/newgem exists, use --force to override
    """

  Scenario: WILL squash an existing dir if we use --force
    When I successfully run `methadone tmp/newgem`
    And I run `methadone --force tmp/newgem`
    Then the exit status should be 0

  Scenario: We must supply a dirname
    When I run `methadone`
    Then the exit status should not be 0
    And the stderr should match /'app_name' is required/

  Scenario: Help is properly documented
    When I get help for "methadone"
    Then the exit status should be 0
    And the following options should be documented:
      |--force|
    And the banner should be present
    And the banner should document that this app takes options
    And the banner should document that this app's arguments are:
      |app_name|which is required|
    And there should be a one line summary of what the app does
