
require_relative '../../spec_helper'
require_relative '../../shared/queue/full'
require_relative '../../shared/sizedqueue/full'

ruby_version_is "3.2" do
  describe "SizedQueue#full?" do
    it_behaves_like :queue_full?, :full?, -> { SizedQueue.new(1_000_001) }
  end
  describe "SizedQueue#full?" do
    it_behaves_like :sizedqueue_full?, :full?, -> n { SizedQueue.new(n) }
  end
end
