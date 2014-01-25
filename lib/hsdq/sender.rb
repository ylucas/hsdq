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
        send_message message, spark
      else
        false
      end
    end

    def send_message(message, spark)
      # avoid further processing into the multi redis command
      channel_name = message[:sent_to]
      h_key        = hsdq_key message
      burst_j      = message.to_json
      spark_j      = spark.to_json
      bkey         = burst_key(message)

      cx_data.multi do
        cx_data.hset   h_key,   bkey, burst_j
        cx_data.expire h_key,   259200 #3 days todo set by options
        cx_data.rpush  channel_name, spark_j
      end
    end

    # add the missing parts to the message
    def prepare_message(message)
      message[:sender]           = channel
      message[:uid]            ||= current_uid || SecureRandom.uuid
      message[:spark_uid]        = SecureRandom.uuid
      message[:tstamp]           = Time.now.utc
      message[:context]          = context_params
      message[:previous_sender]  = previous_sender
      message[:sent_to]        ||= sent_to
      message
    end

    # generate the spark from the message (everything in the spark must be into the message as this is ephemeral)
    def build_spark(message)
      keys = [:sender, :uid, :spark_uid, :tstamp, :context, :previous_sender, :type, :topic, :task ]
      spark = keys.inject({}) { |memo, param| memo.merge(param => message[param]) }
      spark
    end

    def valid_keys?(message)
      [:sender, :sent_to, :type, :uid] - message.keys == []
    end

  end
end