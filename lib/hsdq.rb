require 'redis'

require_relative "hsdq/connectors"
require_relative "hsdq/listener"
require_relative "hsdq/sender"

module Hsdq
  include Connectors
  include Listener
  include Sender

  Thread.abort_on_exception = true # Uncomment for debugging


end