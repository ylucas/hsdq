
module Hsdq
  # The methods in this module are shared by different modules
  module Shared

    def placeholder
      "This is a placeholder, you must implement this method in your hsdq class"
    end

    def valid_type?(type)
      [:request, :ack, :callback, :feedback, :error].include? type.to_sym
    end

    # Build the namespaced key for the main hash storing the message history (collection of 'burst')
    # @param [Hash] message_or_spark a burst or a spark
    # @return [String] the unique key for the main redis hash
    # @return nil if message_or_spark or the uid is nil
    def hsdq_key(message_or_spark)
      return unless message_or_spark
      "hsdq_h_#{message_or_spark[:uid]}" if message_or_spark[:uid]
    end

    # Build the namespaced key for the spark and burst unique shared uid
    # @param [Hash] spark
    # @return [String] the unique namespaced key
    # @return nil if spark or the spark_uid is nil
    def burst_key(spark)
      return unless spark &&
      "#{spark[:type]}_#{spark[:spark_uid]}" if spark[:type] && spark[:spark_uid]
    end

    # Build the namespaced key for the main session hash
    # @param [string] session_id the unique uid for the session
    # @return [String] the unique namespaced key
    # @return nil if session_id
    def session_key(session_id)
      return unless session_id
      "hsdq_s_#{session_id}"
    end

  end
end