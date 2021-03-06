require "redis"
require_relative "connectors"
require_relative "utilities"

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
    def hsdq_start(channel, options)
      hsdq_add_options(options) if options
      hsdq_start!
      hsdq_loop(channel)
    end

    # Set the flag to stop processing the queue
    # @return [Boolean] false
    def hsdq_stop!
      @hsdq_running = false
    end

    # Set the flag to allow processing the queue
    # @return [Boolean] true
    def hsdq_start!
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
    # @return [Boolean] true when listening is not allowed
    def hsdq_stopped?
      !hsdq_running?
    end

    # When true allow the listener to start
    # When set to false, the listener exit the listening loop. This is mostly to exit gracefully the program
    # The listener needs to be restarted specifically, if need to run again
    # @return [Boolean] true when allowing the listener to stay in listening mode
    def hsdq_alive?
      @hsdq_alive = true if @hsdq_alive.nil?
      @hsdq_alive
    end

    # Flag break the listening loop if true.
    # @return [Boolean]
    def hsdq_exit?
      @hsdq_exit
    end

    # Set exit to force the listening loop to exit.
    def hsdq_exit!
      @hsdq_exit = true
    end

    # stops the listening loop
    def kill_alive!
      @hsdq_alive = false
    end

    # Start the listener
    # :nocov:
    def start_listener(options={})
      Thread.new { hsdq_start(channel, options) }
      Thread.new { admin_listener }
    end
    # :nocov:

    private
    # Listening loop. Listen to the channel using a blocking left pop.
    # The timeout allow the idle process to watch at regular interval if there is an admin command.
    # The process is listeing only if there is available thread to be started in the pool
    def hsdq_loop(channel)
      p "starting listening channel #{channel}"
      while hsdq_alive?
        if (allow_new_threads? || !hsdq_opts[:threaded]) && hsdq_running?
          raw_spark = cx_listener.blpop(channel, hsdq_opts[:timeout] )
          hsdq_ignit raw_spark, hsdq_opts if raw_spark
        else
          # :nocov:
          sleep 0.01 # occur only when hsdq_max_threads is reached
          # :nocov:
        end
        kill_alive! if hsdq_exit?
      end
    end

  end
end