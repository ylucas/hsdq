require_relative '../../shared/hsdq_shared_setup'

RSpec.describe Hsdq::Threadpool do
  include_context "setup_shared"


  describe "#max_thread_count" do
    context "no value set, use default" do
      it { expect(obj.max_thread_count).to eq 10 }
    end
    context "no value set, options set" do
      before { obj.hsdq_opts[:max_thread_count] = 20 }
      it { expect(obj.max_thread_count).to eq 20 }
    end
    context "argument passed" do
      before { obj.hsdq_opts[:max_thread_count] = 20 }

      it { expect(obj.max_thread_count(30)).to eq 30 }
    end
    context "keep previous argument passed value" do
      before {
        obj.hsdq_opts[:max_thread_count] = 20
        obj.max_thread_count(40)
      }

      it { expect(obj.max_thread_count).to eq 40 }
    end
  end

  describe "#paused" do
     it { expect(obj.paused true).to be true }
     it { expect(obj.paused false).to be false }
  end

  describe "#paused?" do
    context "default to false" do
      it { expect(obj.paused?).to be false }
    end

    context "when set to true" do
      before { obj.paused true }

      it { expect(obj.paused?).to be true }
    end
  end

  describe "#allow_new_threads?" do
    context "not paused and below max threads" do
      it { expect(obj.allow_new_threads?).to be true }
    end
    context "paused" do
      before { obj.paused true }
      it { expect(obj.allow_new_threads?).to be false }
    end
    context "paused" do
      before { obj.max_thread_count 0 }
      it { expect(obj.allow_new_threads?).to be false }
    end
  end

  describe "#hsdq_threads" do
    it { expect(obj.hsdq_threads.class).to eq ThreadGroup }
  end

  describe "#hsdq_thread_add" do
    it "add threads to the group" do
      tg = obj.hsdq_threads
      expect(tg.list.size).to eq 0

      obj.hsdq_threads_add Thread.new {sleep 0.2}

      expect(tg.list.size).to eq 1
    end
  end

  describe "#hsdq_thread_count" do
    before { obj.hsdq_threads_add Thread.new {sleep 0.2} }

    it { expect(obj.hsdq_threads_count).to eq 1 }
  end

  describe "#start_thread" do
    before {
      obj.hsdq_start_thread(->{sleep 0.2})}

    it { expect(obj.hsdq_threads_count).to eq 1 }
  end



end

