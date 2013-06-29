require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Receiver do
  include_context "setup_shared"

  let(:simple_spark_h)    { {message: "my message"} }
  let(:simple_spark)      { simple_spark_h.to_json }
  let(:simple_raw_spark)  { ["a_channel", simple_spark] }
  let(:empty_options)     { {} }
  let(:auth_topics)       { [:martini, :food] }
  let(:auth_tasks)        { [:order, :eat, :drink] }
  let(:valid_spark) { {type: "request",
                       topic: :martini,
                       task: :drink,
                       sender: "an_app",
                       uid: "12345",
                       sent_to: "another_app"} }


  describe "action methods" do
    context "place_holder" do
      %w(hsdq_task hsdq_ack hsdq_callback hsdq_feedback hsdq_error).each do |message_type|
        it { expect(obj.send message_type, "whatever", "whoever").to eq obj.placeholder }
      end
    end
  end

  describe "#get_spark" do
    context "array" do
      it { expect(obj.get_spark(simple_raw_spark)).to eq simple_spark }
    end

    context "json string" do
      it { expect(obj.get_spark('my spark')).to eq 'my spark' }
    end
  end

  describe "#h_spark" do
    let!(:spark) { ({uid: "12345", drink: "ti punch"}) }
    let(:json_spark) { spark.to_json }

    it { expect(obj.h_spark(['channel_name', json_spark])).to eq spark }
  end

  describe "#check_whitelist" do
    it "do not raise if whitelisted" do
      allow(obj).to receive(:whitelisted?) { true }

      expect {obj.check_whitelist(simple_spark, empty_options)}.not_to raise_error
    end
    it "raise if not whitelisted" do
      allow(obj).to receive(:whitelisted?) { false }

      expect {obj.check_whitelist(simple_spark, empty_options)}.to raise_exception
    end
  end

  describe "#whitelisted?" do
    before() do
      obj.hsdq_authorized_tasks auth_tasks
      obj.hsdq_authorized_topics auth_topics
    end

    context "valid spark" do
      it { expect(obj.whitelisted?(valid_spark, empty_options)).to be true }
    end
    context "invalid spark" do
      let(:invalid_spark) { {topic: :martini, task: :whatever, sender: "an_app", uid: "12345", sent_to: "another_app" } }

      it { expect(obj.whitelisted?(invalid_spark, empty_options)).to be false }
    end
  end

    describe "#sparkle" do
  # todo
    end

  describe "#reject_spark" do
    let(:invalid_spark) { {topic: :martini, task: :whatever} }
    before { allow(obj).to receive(:hsdq_send_error)  { true } }

    it { expect(obj.reject_spark(invalid_spark, ArgumentError.new("Illegal argument"))[:data]).to eq "Illegal argument" }
  end

  describe "handle_spark_rejection" do
    spark = {uid: '12345', sender: 'the_sender'}
    let(:error) { ArgumentError.new("you got an error") }
    error_h = {
      sent_to: 'the_sender',
      uid:     '12345',
      sender:  "test_client",
      params:  spark,
      data:    "you got an error"
    }
    it "call hsdq_send_error" do
      expect(obj).to receive(:hsdq_send_error).with(error_h)
      obj.send :reject_spark, spark, error
    end
  end

  describe "#send_ack" do
    let(:ack_msg) { valid_spark }
    let(:expected) { valid_spark.merge sent_to: "an_app", sender: obj.channel }

    context "request" do
      it "reply to the sender" do
        expect(obj).to receive(:hsdq_send_ack).with(expected)

        obj.send_ack valid_spark
      end
    end
    context "Not a request" do
      let(:response_spark) { valid_spark.merge(type: "feedback") }

      it "reply to the sender" do
        expect(obj).not_to receive(:hsdq_send_ack).with(expected)

        obj.send_ack response_spark
      end

      it { expect(obj.send_ack response_spark).to be nil }
    end
  end

  describe "#hsdq_authorized_types" do
    it { expect(obj.hsdq_authorized_types).to eq [:request, :ack, :feedback, :callback, :error] }
  end

  describe "hsdq_authorized_tasks" do
    before { obj.hsdq_opts[:tasks] = [:clean, :shop] }
    let(:tasks) { [:eat, [:drink]] }
    it { expect(obj.hsdq_authorized_tasks(tasks)).to eq [:clean, :shop, :eat, :drink] }
  end

  describe "hsdq_authorized_topics" do
    before { obj.hsdq_opts[:topics] = [:dishes, :milk] }
    let(:topics) { [:fish, [:vodka]] }
    it { expect(obj.hsdq_authorized_topics(topics)).to eq [:dishes, :milk, :fish, :vodka] }
  end

end