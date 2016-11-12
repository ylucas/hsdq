require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Setting do
  include_context "setup_shared"

  describe "#default_opts" do
    it { expect(obj.default_opts).to eq ({:threaded => false, :timeout  => 10}) }
  end

  describe "#hsdq_opts" do
    it { expect(obj.hsdq_opts({:threaded=>true})).to eq ({:threaded => true, :timeout  => 10}) }
  end

  describe "#environmemt" do
    context "set by RAILS_ENV" do
      it { expect(obj.environment).to eq 'test' }
    end

    context "set by parameter" do
      it { expect(obj.environment("development")).to eq 'development' }
    end
  end

  describe "#snakify" do
    it { expect(obj.snakify("MyGoodClass")).to eq 'my_good_class' }
  end

  describe "#channel=" do
    before { obj.channel = "my_channel" }
    it { expect(obj.channel).to eq "my_channel" }
  end

  describe "#channel" do
    context "passed param" do
      it { expect(obj.channel('my_channel')).to eq 'my_channel' }
    end

    context "automated" do
      it { expect(obj.channel).to eq 'test_client' }
    end
  end

  describe "#config_filename" do
    context "parameter provided" do
      it { expect(obj.config_filename("whatever.yml")).to eq "whatever.yml" }
    end

    context "automated" do
      it { expect(obj.config_filename).to eq "test_client.yml" }
    end
  end

  describe "#config_path" do
    context "parameter provided" do
      it { expect(obj.config_path("config/hdsq/")).to eq "config/hdsq/" }
    end

    context "automated" do
      it { expect(obj.config_path).to eq "./config/" }
    end
  end

  describe "#config_file_path" do
    it { expect(obj.config_file_path).to eq "./config/test_client.yml"  }
  end

  describe "#read_options" do
    context "no config file" do
      it { expect(obj.read_opts).to eq obj.default_opts }
    end
  end

  context "file present" do
    let(:good_setup) do
      {exceptions: true,
       threaded: true,
       timeout:  9,
       redis:    {message: {host: "127.0.0.1", port: 6379, db: 2},
                  admin:   {host: "127.0.0.1", port: 6379, db: 2},
                  session: {host: "127.0.0.1", port: 6379, db: 2}
                 }
      }
    end

    context "with config file" do
      it { expect(obj.read_opts('./spec/shared/test_config.yml')).to eq good_setup }
    end
  end

  describe "#set_abort_on_exception" do
    context "parameter :exceptions is true" do

      before do
        obj.hsdq_opts(exceptions: true)
      end

      it { expect(Thread.abort_on_exception).to eq true }
    end

    context "parameter :exceptions is false" do

      before do
        obj.hsdq_opts(exceptions: false)
      end

      it { expect(Thread.abort_on_exception).to eq false }
    end
  end

end
