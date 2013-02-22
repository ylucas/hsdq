module Hsdq

  @redis = Redis.new unless @redis

  # Start hsdq to listen to channel. When a message is obtained, hsd_task will be called
  # If threaded is true the hsd_task will run in a thread otherwise it will be blocking
  def hsdq_start(channel, threaded=true, callback=:hsdq_task)
    @redis = Redis.new unless @redis
    hsdq_loop(channel, threaded)
  end

  def hsdq_stop
    hsdq_run false
  end

  def hsdq_send(channel, message)
    @redis = Redis.new unless @redis
    if channel && message
      @redis.lpush channel, message
      true
    end
  end

  def hsdq_task(message)
    p "do something here"
  end

  def hsdq_run(run=nil)
    @hsdq_run ||= true
    @hsdq_run = run unless nil == run
    @hsdq_run
  end

  private
    # Listening loop
    def hsdq_loop(channel, threaded=true)
      p "listening started"
      while hsdq_run do
        sleep 1
        message = @redis.lpop(channel)
        if threaded
          Thread.new do
            hsdq_task(message)
          end
        else
          hsdq_task(message)
        end
        check_send
      end
    end

end