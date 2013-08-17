require 'redis'

require_relative "../../lib/hsdq/connectors"

module Hsdq
  module Sender
    include Connectors

    def hsdq_send_request(message_h)
      hsdq_send(message_h.merge(:type => :request))
    end

    def hsdq_send_ack(message_h)
      hsdq_send(message_h.merge(:type => :ack))
    end

    def hsdq_send_callback(message_h)
      hsdq_send(message_h.merge(:type => :callback))
    end

    def hsdq_send_feedback(message_h)
      hsdq_send(message_h.merge(:type => :feedback))
    end

    def hsdq_send_error(message_h)
      hsdq_send(message_h.merge(:type => :error))
    end

    def hsdq_send(message_h)
      message_h = prepare_message message_h
      if valid_keys?(message_h) && valid_type?(message_h[:type])
        spark = build_spark(message_h)
        message_h[:spark_uid] = spark[:spark_uid]
        send_message message_h, spark.to_json
      else
        false
      end
    end

    def send_message(message_h, spark)
      channel_name = message_h[:sent_to]
      h_key        = "#{message_h[:uid]}_h"
      cx_sender.multi do
        cx_sender.hset   h_key,   message_key(message_h), message_h.to_json
        cx_sender.expire h_key,   259200 #3 days
        cx_sender.rpush  channel_name, spark
      end
    end

    def message_key(message_h)
      "#{message_h[:type]}_#{message_h[:spark_uid]}"
    end

    def prepare_message(message_h)
      message_h[:sender]   = channel
      # todo get the uid from the process in case of response
      message_h[:uid]    ||= SecureRandom.uuid
      message_h[:tstamp]   = Time.now.utc
      # todo set sent_to from the process in case of response
      # message_h[:sent_to] = "wip_fixme" unless :request == message_h[:type]
      message_h
    end

    def build_spark(message_h)
      keys = [:sender, :uid, :type, :tstamp, :topic, :task ]
      spark = keys.inject({}) { |memo, param| memo.merge(param => message_h[param]) }
      spark[:spark_uid] = "#{SecureRandom.uuid}"
      spark
    end

    def valid_keys?(message_h)
      [:sender, :sent_to, :type, :uid] - message_h.keys == []
    end

    def valid_type?(type)
      [:request, :ack, :callback, :feedback, :error].include? type
    end

  end
end