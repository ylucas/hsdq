

module Hsdq
  module Receiver

    # Placeholder methods for the message types
    def hsdq_request(message, context);  placeholder; end
    def hsdq_ack(message, context);      placeholder; end
    def hsdq_callback(message, context); placeholder; end
    def hsdq_feedback(message, context); placeholder; end
    def hsdq_error(message, context);    placeholder; end

    def hsdq_ignit(raw_spark, options)
      spark = h_spark raw_spark
      send_ack spark
      validate_spark spark, options
      if hsdq_opts[:threaded]
        Thread.new do
          sparkle spark, options
        end
      else
        sparkle spark, options
      end
    end

    # blpop return an array [list_name, data]
    def get_spark(raw_spark)
      raw_spark.kind_of?(Array) ? raw_spark.last : raw_spark
    end

    def h_spark(raw_spark)
      JSON.parse get_spark(raw_spark), {symbolize_names: true}
    end

    # Entry point for the task to process
    def sparkle(spark, options)
      puts spark.inspect
      burst = get_burst spark, options
      context = spark
      Thread.current[:context] = context
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
          hsdq_request burst, context
      end

    end

    def get_burst(spark, _options)
      burst_json = cx_data.hget hsdq_key(spark), burst_key(spark)
      JSON.parse burst_json, {symbolize_names: true} if burst_json
    end

    def validate_spark(spark, options)
      begin
        raise ArgumentError.new("Illegal type #{spark[:type]}") unless valid_type? spark[:type]
        check_whitelist spark, options if 'request' == spark[:type]
      rescue => e
        reject_spark spark, e
      end

    end

    def check_whitelist(spark, options)
      begin
        raise ArgumentError.new("Illegal argument in topic or task") unless whitelisted? spark, options
      rescue => e
        reject_spark spark, e
      end
    end

    def whitelisted?(spark, options)
      valid_topic?(spark, options) && valid_task?(spark, options)
    end

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

    def send_ack(spark)
      return unless ['request', :request].include? spark[:type]
      ack_msg = spark.merge sent_to: spark[:sender], sender: channel
      hsdq_send_ack ack_msg
    end

    def hsdq_authorized_types
      [:request, :ack, :feedback, :callback, :error]
    end

    def hsdq_authorized_tasks(*tasks)
      @hsdq_authorized_tasks ||= [hsdq_opts[:tasks], [tasks]].flatten
    end

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

  end
end