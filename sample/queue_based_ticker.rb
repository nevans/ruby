# ticks once per second, and keeps ticking if a receiver isn't listening
def naive_ticker(interval)
  ticker = Thread::SizedQueue.new 0
  Thread.new do
    loop do # loop catches ClosedQueueError
      ticker.push(Time.now, true)
    rescue ThreadError # queue full; skip this tick
    ensure
      sleep interval
    end
  end
  def ticker.tick; pop   end
  def ticker.stop; close end
  ticker
end

ticker = naive_ticker 0.300
stop_at  = Time.now + 3  # => 16:18:21.182
sleep_at = Time.now + 1  # => 16:18:19.182
while time = ticker.tick
  puts time.strftime("%T.%L")
  if sleep_at <= time && time <= sleep_at + 0.75
    print "snore... "
    sleep 0.75
    puts "wakeup at #{Time.now.strftime('%T.%L')}"
  end
  ticker.stop if stop_at <= time
end

# >> 16:18:18.182
# >> 16:18:18.483
# >> 16:18:18.783
# >> 16:18:19.084
# >> 16:18:19.384
# >> snore... wakeup at 16:18:20.135
# >> 16:18:20.285
# >> 16:18:20.586
# >> 16:18:20.886
# >> 16:18:21.187
