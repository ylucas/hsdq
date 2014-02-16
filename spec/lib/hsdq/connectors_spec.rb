require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Connectors do
  include_context "setup_shared"

  describe "#cx_listener connection" do
    it { expect(obj.cx_listener).to be_an_instance_of Redis }
  end

  describe "#cx_data connection" do
    it { expect(obj.cx_data).to be_an_instance_of Redis }
  end

  describe "#cx_session connection" do
    it { expect(obj.cx_session).to be_an_instance_of Redis }
  end

end
