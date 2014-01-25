require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Sender do
  include_context "setup_shared"

  describe "sender helpers" do
    %w(request ack callback feedback error).each do |action|
      it "call hsdq_send with #{action} key" do
        expect(obj).to receive(:hsdq_send).with({whaterver: "message", type: action.to_sym})

        obj.send "hsdq_send_#{action}", ({whaterver: "message"})
      end
    end
  end

  describe "#build_spark" do
    let!(:spark) { obj.build_spark(basic_message_w_uid) }

    it { expect(spark[:sender]).to eq 'my_app' }
    it { expect(spark[:spark_uid]).to be_an_instance_of String }
    it { expect([:sender, :uid, :type, :tstamp, :topic, :task] - spark.keys).to eq [] }
  end

  describe "#send_message" do
    before { obj.cx_data.flushdb }

    let!(:msg)   { basic_message_w_uid }
    let!(:spark) { obj.build_spark(msg) }

    it "write to a channel" do
      obj.send_message(msg, spark)

      read = JSON.parse(obj.cx_data.lpop("my-channel"))

      expect(read['type']).to eq "request"
      # expect(read['uid']).to  eq "12345"
    end
  end

  describe "#hsdq_send" do
    let!(:spark)        { obj.build_spark(basic_message_w_uid) }
    let!(:spark_json)   { spark.to_json }
    let!(:msg)          { basic_message_w_uid.merge(spark_uid: spark[:spark_uid]) }
    let!(:hkey)         { "hsdq_h_#{msg[:uid]}" }
    let!(:channel_name) { msg[:sent_to] }

    before do
      obj.cx_data.flushdb
      obj.send_message msg, spark
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
    let(:msg) { basic_message.merge :spark_uid => "abcdef" }

    it { expect(obj.burst_key msg).to eq "request_abcdef" }
  end

  describe "#prepare_message" do
    let(:msg) { basic_message }

    it { expect(obj.prepare_message(msg)[:tstamp]).to be_an_instance_of Time }
    it { expect(obj.prepare_message(msg)[:sender]).to be_an_instance_of String }
    it { expect(obj.prepare_message(msg)[:uid]).to    be_an_instance_of String }
  end

  describe "#valid_keys?" do
    let(:msg) { basic_message.merge :uid => "abcdef" }

    it { expect(obj.valid_keys? msg).to be true }
    [:sender, :sent_to, :type, :uid].each do |k|
      specify "key #{k} must be present" do
        msg.delete k
        expect(obj.valid_keys? msg).not_to be true
      end
    end
  end

  def basic_message
    {
      sender:         'my_app',
      sent_to:        'my-channel',
      context:         {reply_to: "other_app", spark_uid: "zxcvb"},
      previous_sender: 'another_app',
      type:            'request',
      topic:           'dishes',
      task:            'clean',
      params:          {:whatever => 'good', :cheese => 'smelly'}
      # -- generated --
      # uid:            '12345',
      # spark_uid:      'qwerty',
      # tstamp:          Time.now.utc,
    }
  end

  def basic_message_w_uid
    basic_message.merge uid: '12345', spark_uid: 'qwerty'
  end

  def bad_message
    {
      # :sender => 'my_app',
      sent_to: 'my-channel',
      uid:     '12345',
      type:    'request',
      topic:   'dishes',
      task:    'clean',
      params:  {:whatever => 'good', :cheese => 'smelly'}
    }
  end

end
