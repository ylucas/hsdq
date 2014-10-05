module Hsdq
  module ThreadStore

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def context(data=nil)
      set_get __method__, data
    end

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def context_params(data=nil)
      set_get __method__, data
    end

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def current_uid(data=nil)
      set_get __method__, data
    end

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def previous_sender(data=nil)
      set_get __method__, data
    end

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def sent_to(data=nil)
      set_get __method__, data
    end

    # Specialized proxy for set_get the key is the method name
    # @see #set_get
    def reply_to(data=nil)
      set_get __method__, data
    end

    # Return the value stored into the corresponding thread.current key only if no data is passed
    # @param [any value] data save data into the corresponding Thread.current key if data is passed
    # @return [Stored value]
    def set_get(key, data=nil)
      Thread.current[key] = data if data
      Thread.current[key]
    end

  end
end