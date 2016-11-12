require_relative 'utilities'

module Hsdq
  # This module provide the original setting for the hsdq class as well as some utility methods
  module Setting

    # Cached hash of the options thus avoiding to pass options all over the place.
    # Initial state read the options from the config file if any provided and merge in it the opts
    # parameter
    # @param [Hash] opts The Options to be added/merged into the options from the config file
    # @return [Hash] of the options
    def hsdq_opts(opts={})
      @hsdq_opts ||= initial_setup opts
    end

    def initial_setup(opts)
      options = read_opts.merge opts
      set_abort_on_exception(options)
      options
    end

    # @return [Hash] the default options
    def default_opts
      @default_opts ||= {
        threaded: false,
        timeout:  10
      }
    end

    def cx_opts
      @cx_options ||= {
        message: {
          host: '127.0.0.1',
          port: 6379,
          db:   2
        },
        admin: {
          host: '127.0.0.1',
          port: 6379,
          db:   2
        },
        session: {
          host: '127.0.0.1',
          port: 6379,
          db:   2
        }
      }.merge hsdq_opts[:redis] || {}
    end

    # Read the config file
    # @param [String] file_path
    # @return [Hash] options from defult and config
    def read_opts(file_path=nil)
      begin
        default_opts.merge! YAML.load_file(file_path || config_file_path)[:"#{environment}"]
      rescue => e
        puts "[warning] config file not read, using default options"
        default_opts
      end
    end

    # cached value for the environment based on Rails.env or command line parameter (scripts do not have Rails.env)
    # @param [String] environment the environment to be force set or nil or nothing
    # @return [String] The environment string
    # @default 'development'
    def environment(environment=nil)
      @environment ||= environment_from_app(environment) || 'development'
    end

    def environment_from_app(environment)
      environment || (defined?(Rails) ? Rails.env : nil) || (RAILS_ENV if defined? RAILS_ENV)
    end

    # @param [String] name the HsdqClassName
    # @return [String] the channel based on the class name
    def channel(name=nil)
      @channel ||= name || snakify(hsdq_get_name.gsub(/^hsdq/i, ""))
    end

    # @return [String] class name
    def hsdq_get_name
      self.respond_to?(:name) ? self.name : self.class.name
    end

    # Force the channel to be set to any name
    # @param [String] name
    # @return [String] the new channel name
    def channel=(name)
      @channel = name
    end

    # @return [String] The name for the config file (cached)
    def config_filename(filename=nil)
      @config_filename ||= filename || "#{snakify(hsdq_get_name.gsub(/^hsdq/i, ""))}.yml"
    end

    # @param [String] path or nil or nothing. Force the path of a value is passed (cahed)
    # @return [String] the path for the config folder, default to config relative the the actual path for a script
    def config_path(path=nil)
      @config_file_path ||= path || "#{(defined?(Rails) ? Rails.root : '.')}/config/"
    end

    # Cached path to the config file
    # @param [String] config_file_path if passed force the value
    # @return [String] The value for the path to the config file
    def config_file_path(config_file_path=nil)
      @config_file_path ||= config_file_path || File.join(config_path, config_filename)
    end

    # sets abort_on_exception for debugging based on environment or parameter
    #
    # @param [Hash] options If options[exception] true,
    # the main thread will break if a child thread break which is what we want in development/test
    # but we do not want that for production
    def set_abort_on_exception(options)
      options[:exceptions] ? Thread.abort_on_exception = true : Thread.abort_on_exception = false
    end

  end
end