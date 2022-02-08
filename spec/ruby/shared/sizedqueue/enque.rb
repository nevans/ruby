describe :sizedqueue_enq, shared: true do
  it "blocks if queued elements exceed size" do
    q = @object.call(1)

    q.size.should == 0
    q.send(@method, :first_element)
    q.size.should == 1

    blocked_thread = Thread.new { q.send(@method, :second_element) }
    sleep 0.01 until blocked_thread.stop?

    q.size.should == 1
    q.pop.should == :first_element

    blocked_thread.join
    q.size.should == 1
    q.pop.should == :second_element
    q.size.should == 0
  end

  it "raises a ThreadError if queued elements exceed size when not blocking" do
    q = @object.call(2)

    non_blocking = true
    add_to_queue = -> { q.send(@method, Object.new, non_blocking) }

    q.size.should == 0
    add_to_queue.call
    q.size.should == 1
    add_to_queue.call
    q.size.should == 2
    add_to_queue.should raise_error(ThreadError)
  end

  ruby_version_is "3.2" do
    it "blocks until a receiver dequeues if size is zero" do
      q = @object.call(0)

      q.size.should == 0
      blocked_thread1 = Thread.new { q.send(@method, :first_element) }
      sleep 0.01 until blocked_thread1.stop?
      q.size.should == 0
      q.num_waiting.should == 1
      blocked_thread2 = Thread.new { q.send(@method, :second_element) }
      sleep 0.01 until blocked_thread2.stop?
      q.size.should == 0
      q.num_waiting.should == 2

      p "popping 1..."
      q.pop.should == :first_element
      p "popped 1..."
      # blocked_thread1.join

      p "popping 2..."
      q.size.should == 0
      q.pop.should == :second_element
      blocked_thread2.join

      non_blocking = true
      add_to_queue = -> { q.send(@method, Object.new, non_blocking) }
      add_to_queue.should raise_error(ThreadError)
    end
  end

  it "interrupts enqueuing threads with ClosedQueueError when the queue is closed" do
    q = @object.call(1)
    q << 1

    t = Thread.new {
      -> { q.send(@method, 2) }.should raise_error(ClosedQueueError)
    }

    Thread.pass until q.num_waiting == 1

    q.close

    t.join
    q.pop.should == 1
  end
end
