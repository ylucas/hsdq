require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::ThreadStore do
  include_context "setup_shared"

  let(:context_h) { {previous: "app_a", spark_uid: "12345"} }

  describe "#set_get" do
    context "set the data based on the key" do
      before { Thread.current[:context] = nil }

      it { expect(obj.set_get(:context, context_h)).to eq context_h }
    end

    context "read the context" do
      before { Thread.current[:context] = context_h }

      it { expect(obj.set_get :context).to eq context_h }
    end
  end

  describe "#context" do
    context "set the context" do
      before { Thread.current[:context] = nil }

      it { expect(obj.context(context_h)).to eq context_h }
    end

    context "read the context" do
      before { Thread.current[:context] = context_h }

      it { expect(obj.context).to eq context_h }
    end
  end

  # each proxy method added into thread_store must have a key in the array
  describe "thread.current proxies" do
    [:context, :context_params, :current_uid, :previous_sender, :sent_to, :reply_to].each do |key|
      it "receive the values" do
        expect(obj).to receive(:set_get).with(key, context_h)

        obj.send key, context_h
      end
    end
  end

end