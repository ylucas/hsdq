module Hsdq
  module Threadpool

    def max_thread_count(max_count=nil)
      @max_thread_count = max_count if max_count
      @max_thread_count ||= hsdq_opts[:max_thread_count] || 10
    end

    def allow_new_threads(allowed)
      @allow_new_threads = allowed
    end

    def allow_new_threads?
      @allow_new_threads = true if @allow_new_threads.nil?
      @allow_new_threads
    end

    def hsdq_threads
      @hsdq_threads ||= ThreadGroup.new
    end

    def hsdq_threads_add(thread)
      hsdq_threads.add thread
    end

    def hsdq_threads_count
      hsdq_threads.list.size
    end

    def hsdq_start_thread(ignition)
      t = Thread.new(&ignition)
      hsdq_threads_add t
    end

  end
end