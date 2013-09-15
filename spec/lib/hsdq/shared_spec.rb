require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Shared do
  include_context "setup_shared"

  describe "#valide_type?" do
    [:request, :ack, :callback, :feedback, :error].each do |type|
      it { expect(obj.valid_type?(type)).to be true }
    end
    it { expect(obj.valid_type?(:whatever)).to be false }
  end

  describe "#hsdq_key" do
    it { expect(obj.hsdq_key({uid: "12345", whatever: "nothing"})).to eq "hsdq_h_12345" }
  end

  describe "#burst_key" do
    it { expect(obj.burst_key({type: :request, spark_uid: '12345'})).to eq "request_12345" }
  end

end