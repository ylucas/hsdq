require 'redis'

require_relative "../../lib/hsdq/connectors"

module Hsdq
  module Sender
    include Connectors

    def hsdq_send(message_h)
      message_h = prepare_message message_h
      #validate_keys? message_h
      spark = build_spark(message_h)
    end

    def send_message(message_h, spark)
      channel = message_h[:sent_to]
      h_key   = "#{message_h[:uid]}_h"
      cx_sender.multi do
        cx_sender.hset   h_key,   message_key(message_h), message_h.to_json
        cx_sender.expire h_key,   259200 #3 days
        cx_sender.rpush  channel, spark
      end
    end

    def message_key(message_h)
      "#{message_h[:type]}_#{message_h[:spark_uid]}"
    end

    def prepare_message(message_h)
      message_h[:sender]   = channel
      # todo get the uid from the process in case of response
      message_h[:uid]    ||= SecureRandom.uui
      message_h[:tstamp]   = Time.now.utc
      # todo set sent_to from the process in case of response
      message_h[:sent_to] = "wip_fixme" unless 'request' == message_h[:type]
      message_h
    end

    def channel(channel_str=nil)
      @channel ||= "sample" # todo automatize
    end

    def build_spark(message_h)
      keys = [:sender, :uid, :type, :tstamp, :topic, :task ]
      spark = keys.inject({}) { |memo, param| memo.merge(param => message_h[param]) }
      spark[:spark_uid] = "#{SecureRandom.uuid}"
      spark.to_json
    end
  end
end