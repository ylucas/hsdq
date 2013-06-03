require_relative '../../shared/hsdq_shared_setup'

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

    it "get the spark" do
      expect(obj).to receive(:sparkle).exactly(1).times
      Redis.new.rpush("my-channel", {message: "my message"}.to_json)
      obj.hsdq_start_one("my-channel", test_options)
    end
  end

end