require 'redis'

require_relative "../../lib/hsdq/connectors"

module Hsdq
  module Sender
    include Connectors

    def hsdq_send(channel, message)
      if channel && message
        cx_sender.rpush channel, message
      end
    end

  end
end