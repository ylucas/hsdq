

module Hsdq
  module Receiver

    # Placeholder methods for the message types
    def hsdq_task(message_h, _context_h);  placeholder; end
    def hsdq_ack(message_h, context_h);      placeholder; end
    def hsdq_callback(message_h, context_h); placeholder; end
    def hsdq_feedback(message_h, context_h); placeholder; end
    def hsdq_error(message_h, context_h);    placeholder; end

    def hsdq_ignit(raw_spark)
      spark = do_spark_h raw_spark
      if whitelisted? spark
        if hsdq_opts[:threaded]
          Thread.new do
            process_spark spark
          end
        else
          process_spark spark
        end
      else
        error_message = "Rejected"
        handle_spark_rejection spark, error_message
      end
    end

    # blpop return an array [list_name, data]
    def get_spark(raw_spark)
      raw_spark.kind_of?(Array) ? raw_spark.last : raw_spark
    end

    def h_spark(raw_spark)
      JSON.parse get_spark(raw_spark), {symbolize_names: true}
    end

    def whitelisted?(spark)
      true # TODO
    end

    def handle_spark_rejection(spark, error_message)
      error = {
        sent_to: spark[:sender],
        uid:     spark[:uid],
        sender:  channel,
        params:  spark,
        data:    error_message
      }
      puts "sending error message: #{error}"
      hsdq_send_error error
    end

    # Entry point for the task to process
    def process_spark(spark)

    end

    def hsdq_authorized_actions
      [:request, :ack, :feedback, :callback, :error]
    end

    def hsdq_authorized_tasks(*tasks)
      @hsdq_authorized_tasks ||= [hsdq_opts[:tasks] + tasks].flatten
    end

    def hsdq_authorized_topics(*topics)
      @hsdq_authorized_topics ||= [hsdq_opts[:topics] + topics].flatten
    end


  end
end