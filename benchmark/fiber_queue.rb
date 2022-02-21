# frozen_string_literal: true

# rubocop:disable Style/ExplicitBlockArgument,Layout/SpaceInsideBlockBraces,Style/BlockDelimiters,Style/CommentedKeyword,Layout/EmptyLineBetweenDefs,Style/NumericPredicate,Style/Semicolon,Style/ParallelAssignment

# just for fun...
module Sugar
  refine Kernel do
    def monotonic_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    def bm
      start = monotonic_now
      yield
    ensure
      puts "completed in %s" % [monotonic_now - start]
    end
  end
  refine Fiber.singleton_class do
    def sync; blocking? ? new(blocking: false){yield}.resume : yield end
  end
end
using Sugar

# a very simple FiberScheduler
class Scheduler

  # an incredibly naive IO selector
  class ThreadDelegageSelector
    MAX_TIMEOUT = nil
    def initialize(scheduler)
      @scheduler = scheduler
      @wakeup_reader, @wakeup_writer = IO.pipe
    end
    def wakeup = @wakeup_writer.write_nonblock ".", exception: false
    def wait(io, events, timeout=nil) = @scheduler.t{io.wait(events, timeout)}
    def select(timeout=nil)
      timeout = timeout&.positive? ? timeout : MAX_TIMEOUT
      IO.select([@wakeup_reader], nil, nil, timeout)
      @wakeup_reader.read_nonblock(1024)
      [[], [], []]
    end
  end

  def initialize(selector: ThreadDelegageSelector)
    @runq     = Queue.new
    @fiber    = Fiber.new(blocking: true){run_loop}
    @selector = selector.new(self)
  end

  # Used when blocking on synchronization (Thread::Mutex#lock,
  # Thread::Queue#pop, Thread::SizedQueue#push, ...)
  def block(blocker, timeout=nil)
    f = Fiber.current
    after(timeout){unblock(blocker, f)} if timeout
    next_fiber(default: @fiber).transfer
  end

  def next_fiber(default: nil)
    return default if @runq.empty?
    f = @runq.pop(true)
    f.alive? ? f : default
  end

  def unblock(_, awoken)
    @runq << awoken
    @selector.wakeup
  end

  def kernel_sleep(seconds = nil)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    block(:sleep, seconds)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end

  def fiber(&block)
    f = Fiber.new(blocking: false, &block)
    unblock :init, f
    f
  end

  def io_wait(...) = @selector.wait(...)

  # cheats
  def t = Thread.new{yield}.value # or we could delegate to a thread-pool
  def address_resolve(h) t{Addrinfo.getaddrinfo(h, nil).map(&:ip_address).uniq} end # rubocop:disable Naming/MethodParameterName
  def process_wait(pid, flags) t{Process::Status.wait(pid, flags)} end

  private

  def run_loop
    i = 0
    while true # rubocop:disable Style/InfiniteLoop
      pp loop: i += 1
      next_fiber&.transfer
      next_time = run_timers
      select next_time
    end
  rescue StopIteration
    # noop
  rescue Exception => e # rubocop:disable Lint/RescueException
    $stderr.puts "unhandled error [%s] %s" % [e.class, e]
    $stderr.puts " - #{caller.join("\n - ")}"
  ensure
    @fiber = nil
    Fiber.set_scheduler nil
    $stderr.puts "scheduler closed"
    exit! 1
  end

  def run_timers = nil # cheat, no timers here

end
scheduler = Scheduler.new
Fiber.set_scheduler scheduler

##################################################################
puts "=" * 72
puts "fiber_queue"

bm{
  n = 10_000_000
  n = 1_000
  q = Thread::Queue.new
  consumer = Thread::SizedQueue.new 1
  Fiber.schedule {
    while q.pop
      # consuming
    end
    consumer.close
  }

  Fiber.schedule {
    n.times{
      q.push true
    }
    q.push nil
  }

  Fiber.sync { consumer.pop }
}

max = 100

##################################################################
scheduler = Scheduler.new
Fiber.set_scheduler scheduler
puts "=" * 72
puts "fiber_sized_queue"

bm {
  # one producer, one consumer
  n = 1_000_000
  q = Thread::SizedQueue.new(max)
  consumer = Thread::SizedQueue.new 1
  Fiber.schedule {
    while q.pop
      # consuming
    end
    consumer.close
  }

  Fiber.schedule {
    while n > 0
      q.push true
      n -= 1
    end
    q.push nil
  }

  Fiber.sync{consumer.pop}
}

##################################################################
scheduler = Scheduler.new
Fiber.set_scheduler scheduler
puts "=" * 72
puts "fiber_sized_queue2"

bm {
  # one producer, many consumers
  n = 1_000_000
  m = 10
  q = Thread::SizedQueue.new(max)
  consumers = m.times.map do
    consumer = Thread::SizedQueue.new 1
    Fiber.schedule do
      while q.pop
        # consuming
      end
      consumer.close
    end
    consumer
  end

  producer = Thread::SizedQueue.new 1
  Fiber.schedule do
    while n > 0
      q.push true
      n -= 1
    end
    m.times { q.push nil }
    producer.close
  end

  Fiber.sync {
    producer.pop
    consumers.each(&:pop)
  }
}

##################################################################
scheduler = Scheduler.new
Fiber.set_scheduler scheduler
puts "=" * 72
puts "fiber_sized_queue3"

bm {
  # many producers, one consumer
  n = 1_000_000
  m = 10
  q = Thread::SizedQueue.new(max)
  consumer = Thread::SizedQueue.new 1
  Fiber.schedule do
    while q.pop
      # consuming
    end
    consumer.close
  end

  producers = m.times.map do
    producer = Thread::SizedQueue.new 1
    Fiber.schedule do
      while n > 0
        q.push true
        n -= 1
      end
      producer.close
    end
    producer
  end

  Fiber.sync {
    producers.each(&:pop)
    q.push nil
    consumer.pop
  }
}

##################################################################
scheduler = Scheduler.new
Fiber.set_scheduler scheduler
puts "=" * 72
puts "fiber_sized_queue4"

bm {
  # many producers, many consumers
  nr = 1_000_000
  n = 10
  m = 10
  q = Thread::SizedQueue.new(max)
  consumers = n.times.map do
    consumer = Thread::SizedQueue.new 1
    Fiber.schedule do
      while q.pop
        # consuming
      end
      consumer.close
    end
    consumer
  end

  producers = m.times.map do
    producer = Thread::SizedQueue.new 1
    Fiber.schedule do
      while nr > 0
        q.push true
        nr -= 1
      end
      producer.close
    end
    producer
  end

  Fiber.sync {
    producers.each(&:pop)
    n.times { q.push nil }
    consumers.each(&:pop)
  }
}
