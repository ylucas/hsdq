require 'redis'
require 'hsdq'
require 'json'

require_relative '../spec_helper'

class HsdqTestClient
  include Hsdq
  # def self.name; 'HsdqTestClient'; end

    # run the loop only one time for testing pupose
  def hsdq_start_one(channel, options={})
    hsdq_opts(options)
    hsdq_stop!
    hsdq_loop(channel)
  end

end

RSpec.shared_context 'setup_shared' do
  let(:obj) { HsdqTestClient.new }
  # let(:dum_klass) { class HsdqDummyKlass; extend Hsdq; end }

  def test_options
    {
      :threaded => false,
      :timeout  => 1
    }
  end

end