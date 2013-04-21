require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Sender do
  include_context "setup_shared"

  describe "#build_spark" do
    let!(:spark) { JSON.parse(obj.build_spark(basic_message_h)) }

    it { expect(spark['sender']).to eq 'my_app' }
    it { expect(spark['spark_uid']).to be_an_instance_of String }
    it { expect(%w(sender uid type tstamp topic task ) - spark.keys).to eq [] }
  end

  describe "#send_message" do
    before { Redis.new.flushdb }

    let!(:msg)   { basic_message_h }
    let!(:spark) { obj.build_spark(msg) }

    it "write to a channel" do
      obj.send_message(basic_message_h, spark)

      read = JSON.parse(Redis.new.lpop("my-channel"))

      expect(read['type']).to eq "request"
      expect(read['uid']).to  eq "12345"
    end
  end

  describe "#message_key" do
    let(:msg) { basic_message_h.merge :spark_uid => "abcdef" }

    it { expect(obj.message_key msg).to eq "request_abcdef" }
  end

  describe "#prepare_message" do
    let(:msg) { basic_message_h.merge :spark_uid => "abcdef" }

    it { expect(obj.prepare_message(msg)[:tstamp]).to be_an_instance_of Time }
    it { expect(obj.prepare_message(msg)[:sender]).to be_an_instance_of String }
    it { expect(obj.prepare_message(msg)[:uid]).to    be_an_instance_of String }
  end

  describe "#valid_keys?" do
    let(:msg) { basic_message_h.merge :spark_uid => "abcdef" }

    it { expect(obj.valid_keys? msg).to be true }
    [:sender, :sent_to, :type, :uid].each do |k|
      specify "key #{k} must be present" do
        msg.delete k
        expect(obj.valid_keys? msg).not_to be true
      end
    end
  end

  describe "#valide_type?" do
    [:request, :ack, :callback, :feedback, :error].each do |type|
      it { expect(obj.valid_type?(type)).to be true }
    end
    it { expect(obj.valid_type?(:whatever)).to be false }
  end

  def basic_message_h
    {
      :sender => 'my_app',
      :sent_to => 'my-channel',
      :uid    => '12345',
      :type   => 'request',
      # :tstamp => nil,
      :tipc   => 'dishes',
      :task   => 'clean',
      :params => {:whatever => 'good', :cheese => 'smelly'}
    }
  end

  def bad_message_h
    {
      # :sender => 'my_app',
      :sent_to => 'my-channel',
      :uid    => '12345',
      :type   => 'request',
      # :tstamp => nil,
      :tipc   => 'dishes',
      :task   => 'clean',
      :params => {:whatever => 'good', :cheese => 'smelly'}
    }
  end

end
