module Hsdq

  def redis
    @redis ||= Redis.new
  end

  # Start hsdq to listen to channel. When a message is obtained, hsd_task will be called
  # If threaded is true the hsd_task will run in a thread otherwise it will be blocking
  def hsdq_start(channel, threaded=true, callback=:hsdq_task)
    @redis ||= Redis.new
    hsdq_loop(channel, threaded)
  end

  def hsdq_stop
    hsdq_run false
  end

  def hsdq_run(value=nil)
    @hsdq_run ||= true
    @hsdq_run = value unless nil == value
    @hsdq_run
  end

  def hsdq_send(channel, message)
    @channel = channel
    @message = message
  end

  def check_send
    @redis = Redis.new unless @redis
    if @channel && @message
      @redis.lpush @channel, @message
      @channel = nil
      @message = nil
    end
  end

  def hsdq_task(message)
    p "do something here"
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