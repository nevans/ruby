describe :queue_full?, shared: true do
  it "always returns false when Queue is not full" do
    queue = @object.call
    queue.full?.should be_false
    1000.times do
      1000.times do
        queue << :item
      end
      queue.full?.should be_false
    end
  end

  it "returns true when Queue is closed" do
    queue = @object.call
    queue.close
    queue.full?.should be_true
  end
end
