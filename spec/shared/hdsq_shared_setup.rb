require 'redis'
require 'hsdq'

require_relative '../spec_helper'

class TestClient
  include Hsdq
  def self.name; 'TestClient'; end

    # run the loop only one time for testing pupose
  def hsdq_start_one(channel, options={})
    hsdq_opts(options)
    hsdq_stop!
    hsdq_loop(channel)
  end

end

RSpec.shared_context 'setup_shared' do
  let(:obj) { TestClient.new }

  def test_options
    {
      :threaded => false,
      :timeout  => 1
    }
  end

end