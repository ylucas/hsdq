require 'redis'

require_relative "connectors"

module Hsdq
  # This module is holding the methods for the class listener.
  # The listener is connected to the Redis instance with the blocking cx_listener connection
  #
  # It is popping the "Spark" (ephemeral part of the message) from the list.
  # When a spark is popped, it is validated and processed in the receiver module.
  module Listener
    include Connectors

    # Start hsdq to listen to channel.
    # @param [String] channel The channel the hsdq class will be listening
    # @param [Hash] options The hsdq class option from the config file and/or additional parameters passed
    def hsdq_start(channel, options=hsdq_opts)
      hsdq_opts(options)
      hsdq_run!
      hsdq_loop(channel)
    end

    # Set the flag to stop processing the queue
    # @return [Boolean] false
    def hsdq_stop!
      @hsdq_running = false
    end

    # Set the flag to allow processing the queue
    # @return [Boolean] true
    def hsdq_run!
      @hsdq_running = true
    end

    # Flag allowing or not the processing of the queue
    # @return [Boolean] true when listening is allowed
    def hsdq_running?
      @hsdq_running = true if @hsdq_running.nil?
      @hsdq_running
    end

    # Opposite or hsdq_running.
    # @see hsdq_running?
    # @return [Boolean] true when listening is nor allowed
    def hsdq_stopped?
      !hsdq_running?
    end

    # Flag breaking the listening loop if true. True for normal operation.
    # This is useful for running once in test or for later use to stop and exit the process
    # @return [Boolean]
    def hsdq_exit?
      @hsdq_exit = false if @hsdq_exit.nil?
      @hsdq_exit
    end

    # Set exit to force the listening loop to exit.
    def hsdq_exit!
      @hsdq_exit = true
    end

    # Start the listener
    # :nocov:
    def start_listener
      Thread.new { hsdq_start(channel) }
    end
    # :nocov:

    private
    # Listening loop. Listen to the channel using a blocking left pop.
    # The timeout allow the idle process to watch at regular interval if there is an admin command.
    # The process is listeing only if there is available thread to be started in the pool
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