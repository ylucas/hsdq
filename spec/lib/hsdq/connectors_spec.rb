require_relative '../../shared/hdsq_shared_setup'

RSpec.describe Hsdq::Connectors do
  include_context "setup_shared"

  describe "#cx_listener connection" do
    it { expect(obj.cx_listener).to be_an_instance_of Redis }
  end

  describe "#cx_sender connection" do
    it { expect(obj.cx_listener).to be_an_instance_of Redis }
  end



end
