require 'redis'

require_relative "../../lib/hsdq/connectors"

module Hsdq
  module Sender
    include Connectors

    def hsdq_send_request(message)
      hsdq_send(message.merge(type: :request))
    end

    def hsdq_send_ack(message)
      hsdq_send(message.merge(type: :ack))
    end

    def hsdq_send_callback(message)
      hsdq_send(message.merge(type: :callback))
    end

    def hsdq_send_feedback(message)
      hsdq_send(message.merge(type: :feedback))
    end

    def hsdq_send_error(message)
      hsdq_send(message.merge(type: :error))
    end

    def hsdq_send(message)
      message = prepare_message message
      if valid_keys?(message) && valid_type?(message[:type])
        spark = build_spark(message)
        message[:spark_uid] = spark[:spark_uid]
        send_message message, spark.to_json
      else
        false
      end
    end

    def send_message(message, spark)
      channel_name = message[:sent_to]
      h_key        = hsdq_key message
      cx_data.multi do
        cx_data.hset   h_key,   message_key(message), message.to_json
        cx_data.expire h_key,   259200 #3 days
        cx_data.rpush  channel_name, spark
      end
    end

    def message_key(message)
      "#{message[:type]}_#{message[:spark_uid]}"
    end

    def prepare_message(message)
      message[:sender]   = channel
      # todo get the uid from the process in case of response
      message[:uid]    ||= SecureRandom.uuid
      message[:tstamp]   = Time.now.utc
      # todo set sent_to from the process in case of response
      # message[:sent_to] = "wip_fixme" unless :request == message[:type]
      message
    end

    def build_spark(message)
      keys = [:sender, :uid, :type, :tstamp, :topic, :task ]
      spark = keys.inject({}) { |memo, param| memo.merge(param => message[param]) }
      spark[:spark_uid] = "#{SecureRandom.uuid}"
      spark
    end

    def valid_keys?(message)
      [:sender, :sent_to, :type, :uid] - message.keys == []
    end

  end
end