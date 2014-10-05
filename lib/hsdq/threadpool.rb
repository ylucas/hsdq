module Hsdq
  # This module is used to manage the threads
  module Threadpool

    # The maximum number of threads allowed to run at the same time. This is setter and a cached getter.
    # @param [Integer or nil] max_count The max count to be set if passed if nil or no param, do not change the the value.
    # @return [Integer] the max allowed number of threads
    def max_thread_count(max_count=nil)
      @max_thread_count = max_count if max_count
      @max_thread_count ||= hsdq_opts[:max_thread_count] || 10
    end

    # Set paused flag
    # @param [Boolean] paused
    def paused(paused)
      @paused = paused
    end

    # @return [Boolean] true is paused
    def paused?
      @paused = false if @paused.nil?
      @paused
    end

    # @return [Boolean] true if below the max number of allowed thread
    def allow_new_threads?
      hsdq_threads_count < max_thread_count && !paused?
    end

    # Cached ThreadGroup instance holding the threads for a given hsdq class
    # @return [ThreadGroup]
    def hsdq_threads
      @hsdq_threads ||= ThreadGroup.new
    end

    # Add a thread to the thread group
    # @param [Thread]
    # @return [Threadgroup] the hdsq thread goup
    def hsdq_threads_add(thread)
      hsdq_threads.add thread
    end

    # @return the number of thread in the thread group
    def hsdq_threads_count
      hsdq_threads.list.size
    end

    # Start a new thread and add it to the thread group
    # @param [Proc] the thread staring block
    # @return [TheadGroup] the hdsq thread goup
    def hsdq_start_thread(ignition)
      t = Thread.new(&ignition)
      p "New thread: #{t}"
      hsdq_threads_add t
    end

  end
end