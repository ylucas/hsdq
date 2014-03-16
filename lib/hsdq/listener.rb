require 'redis'

require_relative "connectors"

module Hsdq
  module Listener
    include Connectors

    # Start hsdq to listen to channel. When a message is obtained, hsd_task will be called
    # If threaded is true the hsd_task will run in a thread otherwise it will be blocking
    def hsdq_start(channel, options=hsdq_opts)
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
      @hsdq_running = true if @hsdq_running.nil?
      @hsdq_running
    end

    def hsdq_stopped?
      !hsdq_running?
    end

    # useful for running once in test
    def hsdq_exit?
      @hsdq_exit = false if @hsdq_exit.nil?
      @hsdq_exit
    end

    def hsdq_exit!
      @hsdq_exit = true
    end

    # :nocov:
    def start_listener
      Thread.new { hsdq_start(channel) }
    end
    # :nocov:

    private
      # Listening loop
    def hsdq_loop(channel)
      p "staring listening"
      while hsdq_running?
        if allow_new_threads? || !hsdq_opts[:threaded]
          raw_spark = cx_listener.blpop(channel, hsdq_opts[:timeout] )
          hsdq_ignit raw_spark, hsdq_opts if raw_spark
        else
          # :nocov:
          sleep 0.01 # occur only when hsdq_max_threads is reached
          # :nocov:
        end
        hsdq_stop! if hsdq_exit?
      end
    end

  end
end