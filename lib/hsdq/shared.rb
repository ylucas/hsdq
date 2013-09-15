
module Hsdq
  module Shared

    def placeholder
      "This is a placeholder, you must implement this method in your hsdq class"
    end

    def valid_type?(type)
      [:request, :ack, :callback, :feedback, :error].include? type.to_sym
    end

    def hsdq_key(message_or_spark)
      "hsdq_h_#{message_or_spark[:uid]}"
    end

    def burst_key(spark)
      "#{spark[:type]}_#{spark[:spark_uid]}"
    end

  end
end