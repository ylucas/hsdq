require_relative '../spec_helper'

require 'redis'
require 'hsdq.rb'

RSpec.describe Hsdq do

  class TestClient
    extend Hsdq
    def name; 'TestClient'; end
  end

  let(:obj) { TestClient }

  describe "#cx_listener connection" do
    it { expect(obj.cx_listener).to be_an_instance_of Redis }
  end

  describe "#cx_sender connection" do
    it { expect(obj.cx_listener).to be_an_instance_of Redis }
  end

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

  describe "read write on redis" do
    before { Redis.new.flushall }

    it "write  to a channel" do
      obj.hsdq_send("my-channel", "my message")
      expect(Redis.new.lpop("my-channel")).to eq "my message"
    end

    it "listen to a channel" do
      expect(obj).to receive(:hsdq_task).exactly(1).times
      Redis.new.rpush("my-channel", "my message")
      obj.hsdq_start_one("my-channel", false)
    end
  end

end