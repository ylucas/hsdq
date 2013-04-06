require 'redis'

require_relative "connectors"

module Hsdq
  module Listener
    include Connectors

    # Start hsdq to listen to channel. When a message is obtained, hsd_task will be called
    # If threaded is true the hsd_task will run in a thread otherwise it will be blocking
    def hsdq_start(channel, options={})
      hsdq_opts(options)
      hsdq_run!
      hsdq_loop(channel)
    end

    def hsdq_stop!
      @hsdq_running = false
    end

    def hsdq_run!
      @hsdq_running = true
    end

    def hsdq_running?
      !!@hsdq_running
    end

    def hsdq_stopped?
      !@hsdq_running
    end

    def hsdq_task(message)
      p "do something here #{message}"
    end

    def hsdq_opts(opts={})
      # todo here read from yml file
      @hsdqopts ||= default_opts.merge opts
    end

    def default_opts
      @default_opts ||= {
        :threaded => false,
        :timeout  => 60
      }
    end

    private
      # Listening loop
      def hsdq_loop(channel)
        p "listening started"
        loop  do
          message = cx_listener.blpop(channel, hsdq_opts[:timeout] )
          if hsdq_opts[:threaded]
            Thread.new do
              hsdq_task(message)
            end
          else
            hsdq_task(message)
          end
          break if hsdq_stopped?
        end
      end

    def start_listener
      Thread.new { hsdq_start(channel, {:threaded => true}) }
    end

  end
end