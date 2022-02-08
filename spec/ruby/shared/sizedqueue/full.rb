describe :sizedqueue_full?, shared: true do
  it "returns true when SizedQueue has max items" do
    q = @object.call(10)
    10.times do
      q << :item
    end
    q.full?.should be_true
  end

  it "returns false when Queue has fewer than max items" do
    q = @object.call 10
    q.full?.should be_false
    9.times do
      q << :item
      q.full?.should be_false
    end
    q.full?.should be_false
  end

  it "returns false when SizedQueue is unbuffered and has no waiting reciever" do
    q = @object.call 0
    q.full?.should be_true
  end

  it "returns true when SizedQueue is unbuffered and any waiting reciever" do
    q = @object.call 0
    reciever = Thread.new { q.pop rescue nil }
    sleep 0.01 until reciever.stop?
    q.full?.should be_false
  ensure
    q.close
    reciever.join
  end
end
