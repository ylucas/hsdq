require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Utilities do
  include_context "setup_shared"

  describe "#deep_symbolize" do
    let(:stringy_h)  { {"a" => 1, "b" => {"c" => {"d" => 5}}} }
    let(:symbolized) { {a: 1, b: {c: {d: 5}}} }

    it { expect(obj.deep_symbolize(stringy_h)).to eq symbolized }
    it { expect(obj.deep_symbolize(symbolized)).to eq symbolized }
  end

  describe "#snakify" do
    it { expect(obj.snakify("MyGoodClass")).to eq 'my_good_class' }
  end

end
