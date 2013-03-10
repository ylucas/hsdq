require 'redis'
require 'eventmachine'

module Hsdq
  Thread.abort_on_exception = true # Uncomment for debugging

  # establish listener connection
  def cx_listener
    @cx_listener ||= Redis.new
  end

  # establish sender connection
  def cx_sender
    @cx_sender ||= Redis.new
  end

  # Start hsdq to listen to channel. When a message is obtained, hsd_task will be called
  # If threaded is true the hsd_task will run in a thread otherwise it will be blocking
  def hsdq_start(channel, threaded=true, callback=:hsdq_task)
    hsdq_run!
    hsdq_loop(channel, threaded)
  end

  # run the loop only one time for testing pupose
  def hsdq_start_one(channel, threaded=true, callback=:hsdq_task)
    hsdq_stop!
    hsdq_loop(channel, threaded)
  end

  def hsdq_stop!
    @hsdq_running = false
  end

  def hsdq_run!
    @hsdq_running = true
  end

  def hsdq_running?
    !!@hsdq_running
  end

  def hsdq_stopped?
    !@hsdq_running
  end

  def hsdq_send(channel, message)
    if channel && message
      cx_sender.rpush channel, message
    end
  end

  def hsdq_task(message)
    p "do something here #{message}"
  end

  private
    # Listening loop
    def hsdq_loop(channel, threaded=true)
      ensure_reactor
      EM.run do
        p "listening started"
        loop  do
          message = cx_listener.blpop(channel, :timeout => 10 )
          if threaded
            Thread.new do
              hsdq_task(message)
            end
          else
            hsdq_task(message)
          end
          break if hsdq_stopped?
        end
      end
      EM.stop
    end

    def ensure_reactor
      # Start em in a thread and make sure it is running
      Thread.new { EM.run } unless EM.reactor_running?
      sleep 0.1             until  EM.reactor_running?
    end

end