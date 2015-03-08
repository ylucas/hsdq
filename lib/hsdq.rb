# Hsdq: is a High Speed Distributed message Queue built on top of Redis.
# @see Readme.md
#
# This software Copyright 2013-2014 Yves Lucas
# License GPLv3, see LICENSE.txt
#

require 'redis'
require 'json'
require 'securerandom'
require 'byebug'

require_relative "hsdq/shared"
require_relative "hsdq/connectors"
require_relative "hsdq/listener"
require_relative "hsdq/sender"
require_relative "hsdq/setting"
require_relative "hsdq/receiver"
require_relative "hsdq/thread_store"
require_relative "hsdq/session"
require_relative "hsdq/threadpool"
require_relative "hsdq/admin"

module Hsdq
  include Shared
  include Connectors
  include Listener
  include Sender
  include Setting
  include Receiver
  include ThreadStore
  include Session
  include Threadpool
  include Admin

  Thread.abort_on_exception = true # Uncomment for debugging


end