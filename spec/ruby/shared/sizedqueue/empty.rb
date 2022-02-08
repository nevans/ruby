describe :sizedqueue_empty?, shared: true do
  ruby_version_is "3.2" do
    it "returns true on an unbuffered SizedQueue with no waiting senders" do
      q = @object.call 0
      q.empty?.should be_true
    end

    it "returns false on an unbuffered SizedQueue with waiting senders" do
      q = @object.call 0
      sender = Thread.new { q << :item rescue nil }
      sleep 0.01 until sender.stop?
      q.empty?.should be_false
    ensure
      q.close
      sender.join
    end
  end
end
