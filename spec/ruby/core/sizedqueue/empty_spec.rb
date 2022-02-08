require_relative '../../spec_helper'
require_relative '../../shared/queue/empty'
require_relative '../../shared/sizedqueue/empty'

describe "SizedQueue#empty?" do
  it_behaves_like :queue_empty?, :empty?, -> { SizedQueue.new(10) }
end

describe "SizedQueue#empty?" do
  it_behaves_like :sizedqueue_empty?, :empty?, -> n { SizedQueue.new(n) }
end
