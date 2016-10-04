require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Listener do
  include_context "setup_shared"

  describe "#hsdq_start!" do
    it "set hsdq_running? to true" do
      obj.hsdq_start!
      expect(obj.hsdq_running?).to eq true
    end
  end

  describe "#hsdq_stop!" do
    it "set hsdq_running? to false" do
      obj.hsdq_stop!
      expect(obj.hsdq_running?).to be false
    end
  end

  describe "hsdq_running? hsdq_stopped?" do
    context "init" do
      it { expect(obj.hsdq_running?).to be true }
      it { expect(obj.hsdq_stopped?).to be false }
    end
    context "stopped" do
      before { obj.hsdq_stop! }
      it { expect(obj.hsdq_running?).to be false }
      it { expect(obj.hsdq_stopped?).to be true }
    end
  end

  describe "#hsdq_exit?" do
    context "init" do
      it { expect(obj.hsdq_exit?).to be_falsy }
    end
    context "#hsdq_exit! actionned" do
      before { obj.hsdq_exit! }
      it { expect(obj.hsdq_exit?).to be true }
    end
  end

  describe "read from channel" do
    before { obj.cx_data.flushdb }

    it "get the spark" do
      expect(obj).to receive(:sparkle).exactly(1).times
      obj.cx_data.rpush("my-channel", basic_empty_message.to_json)
      obj.hsdq_start_one("my-channel", test_options)
    end
  end

  # # test unstable due to the thread
  # describe "#start_listener" do
  #   before { allow(obj).to receive(:hsdq_start) }
  #   it "start" do
  #     expect(obj).to receive(:hsdq_start)
  #
  #     obj.start_listener
  #   end
  # end

  describe "#hsdq_start" do
    it "load the options, setup runnning start the loop" do
      expect(obj).to receive(:hsdq_opts).with({whatever: "options"})
      expect(obj).to receive(:hsdq_start!)
      expect(obj).to receive(:hsdq_loop).with("one_channel")

      obj.hsdq_start "one_channel", {whatever: "options"}
    end
  end

end