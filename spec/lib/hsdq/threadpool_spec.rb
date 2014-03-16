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

  describe "allow_new_threads" do
     it { expect(obj.allow_new_threads false).to be false }
     it { expect(obj.allow_new_threads true).to be true }
  end

  describe "#allow_new_threads?" do
    context "default to true" do
      it { expect(obj.allow_new_threads?).to be true }
    end

    context "when set to false" do
      before { obj.allow_new_threads false }

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

      obj.hsdq_threads_add Thread.new {}

      expect(tg.list.size).to eq 1
    end
  end

  describe "#hsdq_thread_count" do
    before { obj.hsdq_threads_add Thread.new {} }

    it { expect(obj.hsdq_threads_count).to eq 1 }
  end

  describe "#start_thread" do
    before { obj.hsdq_start_thread(->{})}

    it { expect(obj.hsdq_threads_count).to eq 1 }
  end



end

