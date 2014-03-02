require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Session do
  include_context "setup_shared"

  before { obj.cx_session.flushdb }

  let(:session_id) { "12345" }
  let(:data1)      { ["whatever", "is good"] }
  let(:data2)      { ["whatever", "is good", "anything", "is good too"] }
  let(:data2_h)     { Hash[*data2] }

  describe "#hsdq_session_get" do
    context "one key" do
      before { obj.hsdq_session_set session_id, data1 }

      it { expect(obj.cx_session.hgetall(obj.session_key(session_id))).to eq Hash[*data1] }
    end

    context "multiple keys" do
      before { obj.hsdq_session_set session_id, data2 }

      it { expect(obj.cx_session.hgetall(obj.session_key(session_id))).to eq Hash[*data2] }
    end

    context "pass a hash" do
      before { obj.hsdq_session_set session_id, data2_h }

      it { expect(obj.cx_session.hgetall(obj.session_key(session_id))).to eq Hash[*data2] }
    end
  end

  describe "#hsdq_sessions" do
    before { obj.hsdq_session_set session_id, data2 }

    context "one subkey" do
      it { expect(obj.hsdq_session session_id, "whatever").to eq ["is good"] }
    end

    context "multiple subkeys" do
      it { expect(obj.hsdq_session session_id, "anything", "whatever").to eq ["is good too", "is good"] }
    end

    context "no subkeys" do
      it { expect(obj.hsdq_session session_id).to eq Hash[*data2] }
    end
  end

  describe "#hsdq_session_del" do
    before do
      obj.hsdq_session_set session_id, data2
      obj.hsdq_session_del session_id, ["whatever"]
    end

    it { expect(obj.hsdq_session session_id).to eq Hash["anything", "is good too"] }
  end

  describe "#hsdq_session_destroy" do
    before do
      obj.hsdq_session_set session_id, data2
      obj.hsdq_session_destroy session_id
    end

    it { expect(obj.cx_session.keys).to eq [] }
  end

  describe "#hsdq_session_expire" do
    before do
      obj.hsdq_session_set session_id, data2
      obj.hsdq_session_expire session_id, 20
    end

    it { expect(obj.cx_session.ttl obj.session_key(session_id)).to eq 20 }
  end

  describe "#hsdq_session_expire_in" do
    before do
      obj.hsdq_session_set session_id, data2
      obj.hsdq_session_expire session_id, 20
    end

    it { expect(obj.hsdq_session_expire_in session_id).to eq 20 }
  end

  describe "#hsdq_session_key?" do
    before do
      obj.hsdq_session_set session_id, data2
    end

    it { expect(obj.hsdq_session_key? session_id, "whatever").to be true }
    it { expect(obj.hsdq_session_key? session_id, "nothing").to be false }
  end

end