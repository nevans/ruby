# allows a burst of activity, then backs off to only allow one per interval
def naive_bursty_rate_limiter(interval, burst)
  limiter = Thread::SizedQueue.new burst
  burst.times { limiter << Time.now }
  Thread.new do
    Thread.current.abort_on_exception = true
    loop do
      sleep interval
      limiter.push Time.now # blocks
    end
  end
  def limiter.call; yield pop end
  def limiter.stop; close     end
  limiter
end

limiter = naive_bursty_rate_limiter(0.2, 5)
job = proc do puts Time.now.strftime("%T.%L") end
puts "five fast, then two slow:"
7.times { limiter.call(&job) }
sleep 0.6 # enough time to build back *three* burst, but not all five
puts "three fast, then two slow:"
5.times { limiter.call(&job) }

# >> five fast, then two slow:
# >> 16:33:53.439
# >> 16:33:53.439
# >> 16:33:53.439
# >> 16:33:53.439
# >> 16:33:53.439
# >> 16:33:53.639
# >> 16:33:53.840
# >> three fast, then two slow:
# >> 16:33:54.441
# >> 16:33:54.441
# >> 16:33:54.441
# >> 16:33:54.641
# >> 16:33:54.841
