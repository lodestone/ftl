require 'base_test'
require 'methadone'
require 'stringio'
require 'fileutils'

class TestMain < BaseTest
  include Methadone::Main

  def setup
    @original_argv = ARGV.clone
    ARGV.clear
    @old_stdout = $stdout
    $stdout = StringIO.new
    @logged = StringIO.new
    @custom_logger = Logger.new(@logged)

    @original_home = ENV['HOME']
    fake_home = '/tmp/fake-home'
    FileUtils.rm_rf(fake_home)
    FileUtils.mkdir(fake_home)
    ENV['HOME'] = fake_home
  end

  # Override the built-in logger so we can capture it
  def logger
    @custom_logger
  end

  def teardown
    set_argv @original_argv
    ENV.delete('DEBUG')
    ENV.delete('APP_OPTS')
    $stdout = @old_stdout
    ENV['HOME'] = @original_home
  end

  test_that "my main block gets called by run and has access to CLILogging" do
    Given {
      @called = false
      main do
        begin
          logger.debug "debug"
          logger.info "info"
          logger.warn "warn"
          logger.error "error"
          logger.fatal "fatal"
          @called = true
        rescue => ex
          puts ex.message
        end
      end
    }
    When run_go_safely
    Then main_shouldve_been_called
  end

  test_that "my main block gets the command-line parameters" do
    Given {
      @params = []
      main do |param1,param2,param3|
        @params << param1
        @params << param2
        @params << param3
      end
      set_argv %w(one two three)
    }
    When run_go_safely
    Then {
      @params.should == %w(one two three)
    }
  end

  test_that "my main block can freely ignore arguments given" do
    Given {
      @called = false
      main do
        @called = true
      end
      set_argv %w(one two three)
    }
    When run_go_safely
    Then main_shouldve_been_called
  end

  test_that "my main block can ask for arguments that it might not receive" do
    Given {
      @params = []
      main do |param1,param2,param3|
        @params << param1
        @params << param2
        @params << param3
      end
      set_argv %w(one two)
    }
    When run_go_safely
    Then {
      @params.should == ['one','two',nil]
    }
  end

  test_that "go exits zero when main evaluates to nil or some other non number" do
    [nil,'some string',Object.new,[],4.5].each do |non_number|
      Given main_that_exits non_number
      Then {
        assert_exits(0,"for value #{non_number}") { When run_go!  }
      }
    end
  end

  test_that "go exits with the numeric value that main evaluated to" do
    [0,1,2,3].each do |exit_status|
      Given main_that_exits exit_status
      Then {
        assert_exits(exit_status) { When run_go! }
      }
    end
  end

  test_that "go exits with 70, which is the Linux sysexits.h code for this sort of thing, if there's an exception" do
    Given {
      main do
        raise "oh noes"
      end
    }
    Then {
      assert_exits(70) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "go allows the exception raised to leak through if DEBUG is set in the environment" do
    Given {
      ENV['DEBUG'] = 'true'
      main do
        raise ArgumentError,"oh noes"
      end
    }
    Then {
      assert_raises ArgumentError do
        When run_go!
      end
    }
  end

  test_that "An exception that's not a StandardError causes the excepteion to break through and raise" do
    Given {
      main do
        raise Exception,"oh noes"
      end
    }
    Then {
      ex = assert_raises Exception do
        When run_go!
      end
      assert_equal "oh noes",ex.message
    }
  end

  test_that "Non-methadone exceptions leak through if we configure it that way" do
    Given {
      main do
        raise StandardError,"oh noes"
      end
      leak_exceptions true
    }
    Then {
      ex = assert_raises StandardError do
        When run_go!
      end
      assert_equal "oh noes",ex.message
    }
  end

  test_that "go exits with the exit status included in the special-purpose excepiton" do
    Given {
      main do
        raise Methadone::Error.new(4,"oh noes")
      end
    }
    Then {
      assert_exits(4) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "go allows the special methadone exception to leak through if DEBUG is set in the environment" do
    Given {
      ENV['DEBUG'] = 'true'
      main do
        raise Methadone::Error.new(4,"oh noes")
      end
    }
    Then {
      assert_raises Methadone::Error do 
        When run_go!
      end
    }
  end

  test_that "can exit with a specific status by using the helper method instead of making a new exception" do
    Given {
      main do
        exit_now!(4,"oh noes")
      end
    }
    Then {
      assert_exits(4) { When run_go! }
      assert_logged_at_error "oh noes"
    }
  end

  test_that "when we help_now! we exit and show help" do
    Given {
      @message = any_sentence
      main do
        help_now!(@message)
      end

      opts.on("--switch") { options[:switch] = true }
      opts.on("--flag FLAG") { |value| options[:flag] = value }

      set_argv []
    }

    Then {
      assert_exits(64) { When run_go! }
      assert $stdout.string.include?(opts.to_s),"Expected #{$stdout.string} to contain #{opts.to_s}"
      assert_logged_at_error @message
    }
  end

  test_that "opts allows us to more expediently set up OptionParser" do
    Given {
      @switch = nil
      @flag = nil
      main do
        @switch = options[:switch]
        @flag = options[:flag]
      end

      opts.on("--switch") { options[:switch] = true }
      opts.on("--flag FLAG") { |value| options[:flag] = value }

      set_argv %w(--switch --flag value)
    }

    When run_go_safely

    Then {
      @switch.should be true
      @flag.should == 'value'
    }
  end

  test_that "when the command line is invalid, we exit with 64 and print the CLI help" do
    Given {
      main do
      end

      opts.on("--switch") { options[:switch] = true }
      opts.on("--flag FLAG") { |value| options[:flag] = value }

      set_argv %w(--invalid --flag value)
    }

    Then {
      assert_exits(64) { When run_go! }
      assert $stdout.string.include?(opts.to_s),"Expected #{$stdout.string} to contain #{opts.to_s}"
    }
  end

  test_that "when setting defualts they get copied to strings/symbols as well" do
    Given {
      @flag_with_string_key_defalt = nil
      @flag_with_symbol_key_defalt = nil
      main do
        @flag_with_string_key_defalt = options[:foo]
        @flag_with_symbol_key_defalt = options['bar']
      end
      options['foo'] = 'FOO'
      options[:bar] = 'BAR'
      on("--foo")
      on("--bar")
    }
    When run_go_safely
    Then {
      assert_equal 'FOO',@flag_with_string_key_defalt
      assert_equal 'BAR',@flag_with_symbol_key_defalt
    }
  end

  test_that "omitting the block to opts simply sets the value in the options hash and returns itself" do
    Given {
      @switch = nil
      @negatable = nil
      @flag = nil
      @f = nil
      @other = nil
      @some_other = nil
      @with_dashes = nil
      main do
        @switch      = [options[:switch],options['switch']]
        @flag        = [options[:flag],options['flag']]
        @f           = [options[:f],options['f']]
        @negatable   = [options[:negatable],options['negatable']]
        @other       = [options[:other],options['other']]
        @some_other  = [options[:some_other],options['some_other']]
        @with_dashes = [options[:'flag-with-dashes'],options['flag-with-dashes']]
      end

      on("--switch")
      on("--[no-]negatable")
      on("--flag FLAG","-f","Some documentation string")
      on("--flag-with-dashes FOO")
      on("--other") do 
        options[:some_other] = true
      end

      set_argv %w(--switch --flag value --negatable --other --flag-with-dashes=BAR)
    }

    When run_go_safely

    Then {
      @switch[0].should be true
      @some_other[0].should be true
      @other[0].should_not be true
      @flag[0].should == 'value'
      @f[0].should == 'value'
      @with_dashes[0].should == 'BAR'

      @switch[1].should be true
      @some_other[1].should be nil # ** this is set manually
      @other[1].should_not be true
      @flag[1].should == 'value'
      @f[1].should == 'value'
      @with_dashes[1].should == 'BAR'

      opts.to_s.should match /Some documentation string/
    }
  end

  test_that "without specifying options, [options] doesn't show up in our banner" do
    Given {
      main {}
    }

    Then {
      opts.banner.should_not match /\[options\]/
    }
  end

  test_that "when specifying an option, [options] shows up in the banner" do
    Given {
      main {}
      on("-s")
    }

    Then {
      opts.banner.should match /\[options\]/
    }

  end

  test_that "I can specify which arguments my app takes and if they are required as well as document them" do
    Given {
      main {}
      @db_name_desc = any_string 
      @user_desc = any_string
      @password_desc = any_string

      arg :db_name, @db_name_desc
      arg :user, :required, @user_desc
      arg :password, :optional, @password_desc
    }
    When run_go_safely
    Then {
      opts.banner.should match /db_name user \[password\]$/
      opts.to_s.should match /#{@db_name_desc}/
      opts.to_s.should match /#{@user_desc}/
      opts.to_s.should match /#{@password_desc}/
    }
  end

  test_that "I can specify which arguments my app takes and if they are singular or plural" do
    Given {
      main {}

      arg :db_name
      arg :user, :required, :one
      arg :tables, :many
    }

    Then {
      opts.banner.should match /db_name user tables...$/
    }
  end

  test_that "I can specify which arguments my app takes and if they are singular or optional plural" do
    Given {
      main {}
      
      arg :db_name
      arg :user, :required, :one
      arg :tables, :any
    }

    Then {
      opts.banner.should match /db_name user \[tables...\]$/
    }
  end

  test_that "I can set a description for my app" do
    Given {
      main {}
      description "An app of total awesome"

    }
    Then {
      opts.banner.should match /^An app of total awesome$/
    }
  end

  test_that "when I override the banner, we don't automatically do anything" do
    Given {
      main {}
      opts.banner = "FOOBAR"

      on("-s")
    }

    Then {
      opts.banner.should == 'FOOBAR'
    }
  end

  test_that "when I say an argument is required and its omitted, I get an error" do
    Given {
      main {}
      arg :foo
      arg :bar

      set_argv %w(blah)
    }

    Then {
      assert_exits(64) { When run_go! }
      assert_logged_at_error("parse error: 'bar' is required")
    }
  end

  test_that "when I say an argument is many and its omitted, I get an error" do
    Given {
      main {}
      arg :foo
      arg :bar, :many

      set_argv %w(blah)
    }

    Then {
      assert_exits(64) { When run_go! }
      assert_logged_at_error("parse error: at least one 'bar' is required")
    }
  end

  test_that "when I specify a version, it shows up in the banner" do
    Given  {
      main{}
      version "0.0.1"
    }

    Then {
      opts.banner.should match /^v0.0.1/m
    }
  end

  test_that "when I specify a version, I can get help via --version" do
    Given  {
      main{}
      version "0.0.1"
      set_argv(['--verison'])
    }
    Then run_go_safely
    And {
      opts.to_s.should match /Show help\/version info/m
    }
  end

  test_that "when I specify a version with custom help, it shows up" do
    @version_message = "SHOW ME VERSIONS"
    Given  {
      main{}
      version "0.0.1",@version_message
      set_argv(['--verison'])
    }
    Then run_go_safely
    And {
      opts.to_s.should match /#{@version_message}/
    }
  end

  test_that "default values for options are put into the docstring" do
    Given {
      main {}
      options[:foo] = "bar"
      on("--foo ARG","Indicate the type of foo")
    }
    When {
      @help_string = opts.to_s
    }
    When {
      @help_string.should match /\(default: bar\)/
    }

  end

  test_that "default values for options with several names are put into the docstring" do
    Given {
      main {}
      options[:foo] = "bar"
      on("-f ARG","--foo","Indicate the type of foo")
    }
    When {
      @help_string = opts.to_s
    }
    When {
      @help_string.should match /\(default: bar\)/
    }
  end

  test_that "when getting defaults from an environment variable, show it in the help output" do
    Given app_to_use_environment
    When run_go_safely
    And {
      @help_string = opts.to_s
    }
    Then {
      @help_string.should match /Default values can be placed in the APP_OPTS environment variable/
    }
  end

  test_that "when we want to get opts from the environment, we can" do
    Given app_to_use_environment
    And {
      @flag_value = '56'
      @some_arg = any_string
      set_argv([])
      ENV['APP_OPTS'] = "--switch --flag=#{@flag_value} #{@some_arg}"
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(0,'',&@code)
      @switch.should == true
      @flag.should == @flag_value
      @args.should == [@some_arg]
    }
  end

  test_that "environment args are overridden by the command line" do
    Given app_to_use_environment
    And {
      @flag_value = any_string
      ENV['APP_OPTS'] = "--switch --flag=#{any_string}"
      set_argv(['--flag',@flag_value])
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(0,'',&@code)
      @switch.should == true
      @flag.should == @flag_value
    }
  end

  test_that "we can get defaults from a config file if it's specified" do
    Given app_to_use_rc_file
    And {
      @flag_value = any_string
      rc_file = File.join(ENV['HOME'],'.my_app.rc')
      File.open(rc_file,'w') do |file|
        file.puts ({
          'switch' => true,
          'flag' => @flag_value,
        }.to_yaml)
      end
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(0,&@code)
      @switch.should == true
      @flag.should == @flag_value
    }

  end

  test_that "we can specify an rc file even if it doesn't exist" do
    Given app_to_use_rc_file
    And {
      @flag_value = any_string
      rc_file = File.join(ENV['HOME'],'.my_app.rc')
      raise "Something's wrong, expection rc file not to exist" if File.exists?(rc_file)
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(0,&@code)
      @switch.should == nil
      @flag.should == nil
    }
  end

  test_that "we can use a different format for the rc file" do
    Given app_to_use_rc_file
    And {
      @flag_value = any_string
      rc_file = File.join(ENV['HOME'],'.my_app.rc')
      File.open(rc_file,'w') do |file|
        file.puts "--switch --flag=#{@flag_value}"
      end
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(0,&@code)
      @switch.should == true
      @flag.should == @flag_value
    }

  end

  test_that "with an ill-formed rc file, we get a reasonable error message" do
    Given app_to_use_rc_file
    And {
      @flag_value = any_string
      rc_file = File.join(ENV['HOME'],'.my_app.rc')
      File.open(rc_file,'w') do |file|
        file.puts OpenStruct.new(:foo => :bar).to_yaml
      end
    }
    When {
      @code = lambda { go! }
    }
    Then {
      assert_exits(64,&@code)
    }

  end

private

  def app_to_use_rc_file
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_config_file '.my_app.rc'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_that_exits(exit_status)
    proc { main { exit_status } }
  end

  def app_to_use_environment
    lambda {
      @switch = nil
      @flag = nil
      @args = nil
      main do |*args|
        @switch = options[:switch]
        @flag = options[:flag]
        @args = args
      end

      defaults_from_env_var 'APP_OPTS'

      on('--switch','Some Switch')
      on('--flag FOO','Some Flag')
    }
  end

  def main_shouldve_been_called
    Proc.new { assert @called,"Main block wasn't called?!" }
  end
  
  def run_go_safely
    Proc.new { safe_go! }
  end

  # Calls go!, but traps the exit
  def safe_go!
    go!
  rescue SystemExit
  end

  def run_go!; proc { go! }; end

  def assert_logged_at_error(expected_message)
    @logged.string.should include expected_message
  end

  def assert_exits(exit_code,message='',&block)
    block.call
    fail "Expected an exit of #{exit_code}, but we didn't even exit!"
  rescue SystemExit => ex
    ex.status.should == exit_code
  end

  def set_argv(args)
    ARGV.clear
    args.each { |arg| ARGV << arg }
  end
end
