

module Hsdq
  module Receiver

    # Placeholder methods for the message types
    def hsdq_task(message_h, _context_h);    placeholder; end
    def hsdq_ack(message_h, context_h);      placeholder; end
    def hsdq_callback(message_h, context_h); placeholder; end
    def hsdq_feedback(message_h, context_h); placeholder; end
    def hsdq_error(message_h, context_h);    placeholder; end

    def hsdq_ignit(raw_spark, options)
      spark = h_spark raw_spark
      check_whitelist spark, options
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
      send_ack spark

    end

    def check_whitelist(spark, options)
      begin
        raise ArgumentError.new("Illegal argument") unless whitelisted? spark, options
      rescue => e
        reject_spark spark, e
      end
    end

    def whitelisted?(spark, options)
      hsdq_authorized_topics.include?(spark[:topic]) && hsdq_authorized_tasks.include?(spark[:task])
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
      return unless 'request' == spark[:type]
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

  end
end