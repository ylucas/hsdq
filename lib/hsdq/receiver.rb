
module Hsdq
  # This module process the incoming messages and call one of 5 messages (ack, request, callback, feedback or error)
  # depending on the type of the message.
  module Receiver


    # **Placeholder for request received. You must override hsdq_request in your HsdqXxx class**<br>
    # After this method has run, there will be no further processing.
    #
    # @param [Hash] message, the message to process
    # @param [Hash] context, the request that was originally sent.
    # @return [String] placeholder string message, will be what your method will be returning.
    def hsdq_request(message, context);  placeholder; end
    # **Placeholder for ack received. You must override hsdq_request in your HsdqXxx class**
    # @see #hsdq_request
    def hsdq_ack(message, context);      placeholder; end
    # **Placeholder for callback received. You must override hsdq_request in your HsdqXxx class**
    # @see #hsdq_request
    def hsdq_callback(message, context); placeholder; end
    # **Placeholder for feedback received. You must override hsdq_request in your HsdqXxx class**
    # @see #hsdq_request
    def hsdq_feedback(message, context); placeholder; end
    # **Placeholder for error received. You must override hsdq_request in your HsdqXxx class**
    # @see #hsdq_request
    def hsdq_error(message, context);    placeholder; end

    # Send the ACk and start the processing for the message just received.<br>
    # The processing will be either executed synchronously or a new thread will be started based on the configuration.
    #
    # @param [Json string] spark (ephemeral) just popped out of the queue in json format
    # @param [Hash] HsdqXxx class configuration options
    def hsdq_ignit(raw_spark, options)
      spark = h_spark raw_spark
      send_ack spark
      validate_spark spark, options
      if hsdq_opts[:threaded]
        # :nocov:
        hssdq_start_thread -> { sparkle spark, options }
        # :nocov:
      else
        sparkle spark, options
      end
    end

    # blpop return an array [list_name, data]
    def get_spark(raw_spark)
      raw_spark.kind_of?(Array) ? raw_spark.last : raw_spark
    end

    # return the spark (ephemeral part of the message) from the message list
    # @param [Json string or Array] from the list
    # @return [Hash] spark ready to be used by the system
    def h_spark(raw_spark)
      JSON.parse get_spark(raw_spark), {symbolize_names: true}
    end

    # Entry point for the task to process, this is what is executed in the threads when a message is pulled.
    # - Pull the burst (line with the request or response) from the the hash<br>
    # - Pull the context related to a response if it exist
    # - Set values for the next hop context in case of a request.
    # - Call one of the 5 methods (request, ack, callback, feedback, error) in your hsdqXxx class (or the placeholder)
    # based on the message type
    # @param [Hash] spark
    # @param [Hash] hsdq class options from setup
    def sparkle(spark, options)
      puts spark.inspect
      burst, ctx_burst = get_burst spark, options
      context ctx_burst

      case spark[:type].to_sym
        when :ack
          hsdq_ack burst, context
        when :callback
          hsdq_callback burst, context
        when :feedback
          hsdq_feedback burst, context
        when :error
          hsdq_error burst, context
        when :request
          set_context spark

          hsdq_request burst, context
      end
    end

    # Save for future use context data into the thread_store
    # @param [Hash] spark
    def set_context(spark)
      # store in thread_store for later use
      sent_to spark[:sender]
      previous_sender spark[:sender]
      context_params({ reply_to: spark[:previous_sender], spark_uid: spark[:spark_uid]})
    end

    # Manage pulling:
    # - the burst (persistent action) associated with the spark from the matching Redis hash
    # - if needed the context data
    # @param [Hash] spark
    # @param [Hash] options for the app
    def get_burst(spark, _options={})
      # get the context parameters
      context_h = spark[:context]

      burst_p = -> { cx_data.hget hsdq_key(spark), burst_key(spark) }
      if response?(spark) && context_h
        # save previous_sender in thread_store for later reply
        sent_to context_h[:previous_sender]
        # set the proc for multi redis to pull the initial request
        burst_context_p = -> { cx_data.hget hsdq_key(spark), "request_#{context_h[:spark_uid]}" }
        # exec the redis multi
        burst_j, burst_context_j = pull_burst(burst_p, burst_context_p)
      else
        burst_j, burst_context_j = pull_burst_only burst_p
      end

      burst         = burst_j ? (JSON.parse burst_j, {symbolize_names: true}) : {}
      burst_context = burst_context_j ? (JSON.parse burst_context_j, {symbolize_names: true}) : {}

      [burst, burst_context]
    end

    # Execute a multi transaction to get the burst and the context from Redis in a single call
    # @param [Proc] burst_p query to pull the burst from redis
    # @param [Proc] context_p query to pull the context from redis
    # @return [array] [burst, context]
    def pull_burst(burst_p, burst_context_p)
      cx_data.multi do
        burst_p.call
        burst_context_p.call
      end
    end

    # If there is no context this method is used instead of pull_burst
    # @see #pull_burst
    # @param [Proc] burst_p query to pull the burst from redis
    def pull_burst_only(burst_p)
      [burst_p.call, nil]
    end

    # Spark validation, call valid_type?. If invalid:
    # - an error is sent back to the sender
    # - false is returned to the processing to stop the action.
    # @param [Hash] spark
    # @param [Hash] options Application options
    # @return [Boolean] true in case of valid spark,
    # @return [Hash] the error message if an error is raised
    def validate_spark(spark, options)
      begin
        raise ArgumentError.new("Illegal type #{spark[:type]}") unless valid_type? spark[:type]
        check_whitelist spark, options if 'request' == spark[:type]
      rescue => e
        reject_spark spark, e
      end

    end

    # Call whitelisted? to verify the the topic and task are legit.
    # @param [Hash] spark
    # @param [Hash] options
    # @return [Boolean] if whitelist validation is successful
    # @return [Hash] the error message if an error is raised
    def check_whitelist(spark, options)
      begin
        raise ArgumentError.new("Illegal argument in topic or task") unless whitelisted? spark, options
      rescue => e
        reject_spark spark, e
      end
    end

    # validate the topic and the task
    def whitelisted?(spark, options)
      valid_topic?(spark, options) && valid_task?(spark, options)
    end

    # Send an error message back to the sender
    # @param [Hash] Spark
    # @param [ArgumentError] if invalid
    # @return [Hash] the error message
    def reject_spark(spark, e)
      error = {
        sent_to: spark[:sender],
        uid:     spark[:uid],
        sender:  channel,
        params:  spark,
        data:    e.message
      }
      puts "sending error message: #{error}"
      hsdq_send_error error
      error
    end

    # Send the ack back to the sender in case of a request
    def send_ack(spark)
      return unless ['request', :request].include? spark[:type]
      ack_msg = spark.merge sent_to: spark[:sender], sender: channel
      hsdq_send_ack ack_msg
    end

    # Hash of the internal authorized message types
    def hsdq_authorized_types
      [:request, :ack, :feedback, :callback, :error]
    end

    # Cached value of the tasks authorized to be processed
    # @param [Array] Additional tasks to the one setup in the configuration file
    # @return [Array] the authoriced tasks
    def hsdq_authorized_tasks(*tasks)
      @hsdq_authorized_tasks ||= [hsdq_opts[:tasks], [tasks]].flatten
    end

    # Cached value of the topics authorized to be processed
    # @param [Array] Additional tasks to the one setup in the configuration file
    # @return [Array] the authoriced topics
    def hsdq_authorized_topics(*topics)
      @hsdq_authorized_topics ||= [hsdq_opts[:topics], [topics]].flatten
    end

    def valid_task?(spark, _options)
      return true unless spark[:task] # nil values ok by default add option to reject nil
      hsdq_authorized_tasks.include?(spark[:task].to_sym)
    end

    def valid_topic?(spark, _options)
      return true unless spark[:topic] # nil values ok by default add option to reject nil
      hsdq_authorized_topics.include?(spark[:topic].to_sym)
    end

    # @return [boolean] true if the message received is a response
    def response?(spark)
      [:callback, :feedback, :error].include? spark[:type].to_sym
    end

  end
end