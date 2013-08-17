require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Shared do
  include_context "setup_shared"

  describe "#valide_type?" do
    [:request, :ack, :callback, :feedback, :error].each do |type|
      it { expect(obj.valid_type?(type)).to be true }
    end
    it { expect(obj.valid_type?(:whatever)).to be false }
  end

end