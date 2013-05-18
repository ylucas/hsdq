require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Receiver do
  include_context "setup_shared"

  # let(:valid_spark) {}

  describe "action methods" do
    context "place_holder" do
      %w(hsdq_task hsdq_ack hsdq_callback hsdq_feedback hsdq_error).each do |message_type|
        it { expect(obj.send message_type, "whatever", "whoever").to eq obj.placeholder }
      end
    end
  end

  describe "#get_spark" do
    context "array" do
      it { expect(obj.get_spark(['channnel_name', 'my spark'])).to eq 'my spark' }
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

  describe "handle_spark_rejection" do
    spark = {uid: '12345', sender: 'the_sender'}
    let(:error_msg) { "you got an error" }
    error_h = {
      sent_to: 'the_sender',
      uid:     '12345',
      sender:  "test_client",
      params:  spark,
      data:    "you got an error"
    }
    it "call hsdq_send_error" do
      expect(obj).to receive(:hsdq_send_error).with(error_h)
      obj.send :handle_spark_rejection, spark, error_msg
    end
  end

  describe "#hsdq_authorized_actions" do
    it { expect(obj.hsdq_authorized_actions).to eq [:request, :ack, :feedback, :callback, :error] }
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