

module Hsdq
  module Setting
    def hsdq_opts(opts={})
      @hsdq_opts ||= read_opts.merge opts
    end

    def default_opts
      @default_opts ||= {
        :threaded => false,
        :timeout  => 10
      }
    end

    def read_opts(file_path=nil)
      begin
        default_opts.merge YAML.load_file(file_path || config_file_path)[:"#{environment}"]
      rescue
        puts "[warning] config file not read, using default options"
        default_opts
      end
    end

    def environment(environment=nil)
      environment  ||= (defined?(Rails) ? Rails.env : nil) || RAILS_ENV || 'development'
      @environment ||= environment
    end

    def snakify(string)
      string.split(/(?=[A-Z])/).map(&:downcase).join('_')
    end

    def channel(name=nil)
      @channel ||= name || snakify(hsdq_get_name.gsub(/^hsdq/i, ""))
    end

    def hsdq_get_name
      self.respond_to?(:name) ? self.name : self.class.name
    end

    def channel=(name)
      @channel = name
    end

    def config_filename(filename=nil)
      @config_filename ||= filename || "#{snakify(hsdq_get_name.gsub(/^hsdq/i, ""))}.yml"
    end

    def config_path(path=nil)
      @config_file_path ||= path || "#{(defined?(Rails) ? Rails.root : '.')}/config/"
    end

    def config_file_path(config_file_path=nil)
      @config_file_path ||= config_file_path || File.join(config_path, config_filename)
    end

  end
end