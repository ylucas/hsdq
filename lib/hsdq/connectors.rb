require 'redis'

module Hsdq

  # This module contains the logic for different connection to the redis layer.
  #
  # They can be connected to the same Redis instance, but it is recommended to use different
  # database connections in order to segregate the different usages.
  #
  # In production of large applications you should use different instances for the different layers.
  # The configuration files are named after your class name hsdq_yourclass.yml
  module Connectors

    # Establish the listener connection.
    # IMPORTANT this connection is blocked by the listener and must not be used elsewhere
    # @return [Redis connection] For the listener exclusively
    def cx_listener
      @cx_listener ||= Redis.new cx_opts[:message]
    end

    # Establish an unblocked connection for the sender and also pulling data from Redis
    # @return [Redis connection] This connection is used to send messages as well as to retrieve
    #                            data from the message hash
    def cx_data
      @cx_data ||= Redis.new cx_opts[:message]
    end

    # establish an unblocked connection for the session layer
    # @return [Redis connection] reserved for storing and retrieving the sessions data
    def cx_session
      @cx_session ||= Redis.new cx_opts[:session]
    end

    # establish a connection for the admin channel pub/sub
    # @return [Redis connection] reserved for the admin commands
    def cx_admin
      @cx_admin ||= Redis.new cx_opts[:admin]
    end
  end
end