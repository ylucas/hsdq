require_relative '../../shared/hdsq_shared_setup'

RSpec.describe Hsdq::Sender do
  include_context "setup_shared"

  describe "#hsdq_send" do
    before { Redis.new.flushall }

    it "write to a channel" do
      obj.hsdq_send("my-channel", "my message")
      expect(Redis.new.lpop("my-channel")).to eq "my message"
    end
  end

end
