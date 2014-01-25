require 'redis'
require 'hsdq'
require 'json'

require_relative '../spec_helper'

class HsdqTestClient
  include Hsdq
  # def self.name; 'HsdqTestClient'; end

    # run the loop only one time for testing pupose
  def hsdq_start_one(channel, options={})
    hsdq_opts(options)
    hsdq_stop!
    hsdq_loop(channel)
  end

end

RSpec.shared_context 'setup_shared' do
  let(:obj) { HsdqTestClient.new }
  # let(:dum_klass) { class HsdqDummyKlass; extend Hsdq; end }

  def test_options
    {
      :threaded => false,
      :timeout  => 1
    }
  end

  def basic_message
    {
      sender:         'my_app',
      sent_to:        'my-channel',
      context:         {reply_to: "other_app", spark_uid: "zxcvb"},
      previous_sender: 'another_app',
      type:            'request',
      topic:           'dishes',
      task:            'clean',
      params:          {:whatever => 'good', :cheese => 'smelly'}
      # -- generated --
      # uid:            '12345',
      # spark_uid:      'qwerty',
      # tstamp:          Time.now.utc,
    }
  end

  def basic_message_w_uid
    basic_message.merge uid: '12345', spark_uid: 'qwerty'
  end

  def bad_message
    {
      # :sender => 'my_app',
      # type:    'request',
      sent_to: 'my-channel',
      uid:     '12345',
      topic:   'dishes',
      task:    'clean',
      params:  {:whatever => 'good', :cheese => 'smelly'}
    }
  end

end