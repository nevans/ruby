require_relative '../../spec_helper'
require_relative '../../shared/queue/full'

ruby_version_is "3.2" do
  describe "Queue#full?" do
    it_behaves_like :queue_full?, :full?, -> { Queue.new }
  end
end
