require 'redis'

module Hsdq
  module Connectors
    # establish listener connection,
    # IMPORTANT this connection is blocked by the listener and must not be used elsewhere
    def cx_listener
      @cx_listener ||= Redis.new
    end

    # establish an unblocked connection for the sender and also pulling data from Redis
    def cx_data
      @cx_data ||= Redis.new
    end

    # establish an unblocked connection for the session layer
    def cx_session
      @cx_session ||= Redis.new
    end
  end
end