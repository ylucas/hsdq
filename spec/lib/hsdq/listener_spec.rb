require_relative '../../shared/hdsq_shared_setup'

RSpec.describe Hsdq::Listener do
  include_context "setup_shared"

  describe "#hsdq_run" do
    it "set hsdq_running? to true" do
      obj.hsdq_run!
      expect(obj.hsdq_running?).to eq true
    end
  end

  describe "#hsdq_stop" do
    it "set hsdq_running? to false" do
      obj.hsdq_stop!
      expect(obj.hsdq_running?).to be false
    end
  end

  describe "read from channel" do
    before { Redis.new.flushdb }

    it "listen to a channel" do
      expect(obj).to receive(:hsdq_task).exactly(1).times
      Redis.new.rpush("my-channel", "my message")
      obj.hsdq_start_one("my-channel", test_options)
    end
  end

  describe "#default_opts" do
    it { expect( obj.default_opts).to eq ({:threaded => false, :timeout  => 60}) }
  end

  describe "#hsdq_opts" do
    it { expect( obj.hsdq_opts({:threaded=>true})).to eq ({:threaded => true, :timeout  => 60}) }
  end

end