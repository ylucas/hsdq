module Hsdq
  module ThreadStore

    def context(data=nil)
      set_get __method__, data
    end

    def current_uid(data=nil)
      set_get __method__, data
    end

    def previous_sender(data=nil)
      set_get __method__, data
    end

    def context_burst(data=nil)
      set_get __method__, data
    end

    def sent_to(data=nil)
      set_get __method__, data
    end

    def set_get(key, data=nil)
      Thread.current[key] = data if data
      Thread.current[key]
    end

  end
end