require 'spec_helper'
require 'redis'

require_relative "hsdq/connectors"
require_relative "hsdq/listener"
require_relative "hsdq/sender"
require_relative "hsdq/setting"

module Hsdq
  include Connectors
  include Listener
  include Sender
  include Setting

  Thread.abort_on_exception = true # Uncomment for debugging


end