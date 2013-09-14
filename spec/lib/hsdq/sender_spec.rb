require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Sender do
  include_context "setup_shared"

  describe "#build_spark" do
    let!(:spark) { obj.build_spark(basic_message_h) }

    it { expect(spark[:sender]).to eq 'my_app' }
    it { expect(spark[:spark_uid]).to be_an_instance_of String }
    it { expect([:sender, :uid, :type, :tstamp, :topic, :task] - spark.keys).to eq [] }
  end

  describe "#send_message" do
    before { obj.cx_data.flushdb }

    let!(:msg)   { basic_message_w_uid }
    let!(:spark) { obj.build_spark(msg) }

    it "write to a channel" do
      obj.send_message(msg, spark.to_json)

      read = JSON.parse(Redis.new.lpop("my-channel"))

      expect(read['type']).to eq "request"
      expect(read['uid']).to  eq "12345"
    end
  end

  describe "#hsdq_send" do
    let!(:spark)      { obj.build_spark(basic_message_w_uid) }
    let!(:spark_json)        { spark.to_json }
    let!(:msg)          { basic_message_w_uid.merge(spark_uid: spark[:spark_uid]) }
    let!(:hkey)         { "#{msg[:uid]}_h" }
    let!(:channel_name) { msg[:sent_to] }

    before do
      obj.cx_data.flushdb
      obj.send_message msg, spark_json
    end

    it "create a list if none exist" do
      expect(obj.cx_data.keys).to include channel_name
    end
    it "write the spark in the channel list" do
      expect(obj.cx_data.lpop channel_name).to eq spark_json
    end
    it "create a Redis hash based the message uid" do
      expect(obj.cx_data.keys).to include hkey
    end
    it "write the redis hash" do
      expect(JSON.parse((obj.cx_data.hget hkey, "request_#{spark[:spark_uid]}"), symbolize_names: true)).to eq msg
    end
  end

  describe "#message_key" do
    let(:msg) { basic_message_h.merge :spark_uid => "abcdef" }

    it { expect(obj.message_key msg).to eq "request_abcdef" }
  end

  describe "#prepare_message" do
    let(:msg) { basic_message_h }

    it { expect(obj.prepare_message(msg)[:tstamp]).to be_an_instance_of Time }
    it { expect(obj.prepare_message(msg)[:sender]).to be_an_instance_of String }
    it { expect(obj.prepare_message(msg)[:uid]).to    be_an_instance_of String }
  end

  describe "#valid_keys?" do
    let(:msg) { basic_message_h.merge :uid => "abcdef" }

    it { expect(obj.valid_keys? msg).to be true }
    [:sender, :sent_to, :type, :uid].each do |k|
      specify "key #{k} must be present" do
        msg.delete k
        expect(obj.valid_keys? msg).not_to be true
      end
    end
  end

  def basic_message_h
    {
      :sender  => 'my_app',
      :sent_to => 'my-channel',
      # :uid     => '12345',
      :type    => 'request',
      :topic   => 'dishes',
      :task    => 'clean',
      :params  => {:whatever => 'good', :cheese => 'smelly'}
    }
  end

  def basic_message_w_uid
    basic_message_h.merge uid: '12345'
  end

  def bad_message_h
    {
      # :sender => 'my_app',
      :sent_to => 'my-channel',
      :uid     => '12345',
      :type    => 'request',
      :topic   => 'dishes',
      :task    => 'clean',
      :params  => {:whatever => 'good', :cheese => 'smelly'}
    }
  end

end
