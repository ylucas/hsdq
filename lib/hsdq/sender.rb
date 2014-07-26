require 'redis'

require_relative "../../lib/hsdq/connectors"

# This module is holding the methods for the sender (emitter) for your hsdq class.
#
# It is holding proxy methods setting the correct type to send your messages
module Hsdq
  module Sender
    include Connectors

    # to use by your application to send a request from your hsdq class. This is a Proxy for hsdq_send to send request messages
    #
    # @param [Hash] Request message you want to send
    # @return [Hash] your original message with the system additional parameters
    def hsdq_send_request(message)
      hsdq_send(message.merge(type: :request))
    end

    # Ack message is the acknowledgement that message has been received by the receiver (Subscriber).
    #
    # Ack is sent automatically by the system. This method is to send additional ack messages if needed. (very seldom used)
    #
    # @param [Hash] acknowledge you want to send
    # @return [Hash] your original message with the system additional parameters
    def hsdq_send_ack(message)
      hsdq_send(message.merge(type: :ack))
    end

    # Callback messages are the final step for a successful response.
    #
    # @param [Hash] callback message you want to send
    # @return [Hash] your original message with the system additional parameters
    def hsdq_send_callback(message)
      hsdq_send(message.merge(type: :callback))
    end

    # Feedback messages are the intermediate messages used to update the sender of the progress of it's request.
    #
    # @param [Hash] feedback message you want to send
    # @return [Hash] your original message with the system additional parameters
    def hsdq_send_feedback(message)
      hsdq_send(message.merge(type: :feedback))
    end

    # Error messages are used to return an error message to the sender in case of error during the processing.
    #
    # Error messages are also automatically sent by the system in case of validation error at message recetion.
    #
    # @param [Hash] error message you want to send
    # @return [Hash] your original message with the system additional parameters
    def hsdq_send_error(message)
      hsdq_send(message.merge(type: :error))
    end

    # Generic method to send any type of message. It is preferred to use the the send proxy methods that are setting
    # the correct type for the messate the application has to send: hsdq_send_request, callback etc..
    # The message type must be provided.
    #
    # @param [Hash] message to send
    # @return [Hash] original message with the system additional parameters
    def hsdq_send(message)
      message = prepare_message message
      if valid_keys?(message) && valid_type?(message[:type])
        spark = build_spark(message)
        send_message message, spark
      else
        false
      end
    end

    # Send the message using a Redis multi in order to do everything within a single transaction
    # @param [Hash] message to send, will be stored as an entry in the message hash
    # @param [Hash] spark the ephemeral part of the message. pushed to a list
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

    # Complete the message with the key values needed by the system
    # @param [Hash] message original
    # @return [Hash] message with the additional system data
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

    # generate the spark from the message. The spark is ephemeral so everything in the spark is included into the message hash.
    # @param [Hash] message to be sent
    # @return [Hash] spark, the tiny part pushed to the list
    def build_spark(message)
      keys = [:sender, :uid, :spark_uid, :tstamp, :context, :previous_sender, :type, :topic, :task ]
      spark = keys.inject({}) { |memo, param| memo.merge(param => message[param]) }
      spark
    end

    # validate that the minimun necessary keys are present into the message befoe sendng it.
    # @param [Hash] the full message to be sent (including the system data)
    def valid_keys?(message)
      [:sender, :sent_to, :type, :uid] - message.keys == []
    end

  end
end