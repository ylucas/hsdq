require 'spec_helper'
require 'redis'
require 'json'

require_relative "hsdq/shared"
require_relative "hsdq/connectors"
require_relative "hsdq/listener"
require_relative "hsdq/sender"
require_relative "hsdq/setting"
require_relative "hsdq/receiver"

module Hsdq
  include Shared
  include Connectors
  include Listener
  include Sender
  include Setting
  include Receiver

  Thread.abort_on_exception = true # Uncomment for debugging


end