require 'redis'

module Hsdq
  module Connectors
    # establish listener connection
    def cx_listener
      @cx_listener ||= Redis.new
    end

    # establish sender connection
    def cx_sender
      @cx_sender ||= Redis.new
    end
  end
end