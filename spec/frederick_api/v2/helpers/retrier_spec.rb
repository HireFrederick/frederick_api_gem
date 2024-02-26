# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::Retrier do
  let(:dummy_class) {
    Class.new do
      include FrederickAPI::V2::Helpers::Retrier
      def dummy_method
      end
    end
  }
  let(:retry_times) { 3 }
  let(:calling_times) { 0 }
  let(:dummy_class_instance) { dummy_class.new }
  let(:test_block) { ->{ dummy_class_instance.dummy_method; raise 'Exception: test' } }

  before { allow(FrederickAPI.config).to receive(:retry_times).and_return(retry_times) }

  describe '#retry_block' do
    before do
      allow(dummy_class_instance).to receive(:retry_block).with(retry_times, &test_block).and_call_original
      allow(dummy_class_instance).to receive(:dummy_method).and_call_original
    end

    it 'expects to raise error after 3 retries' do
      expect { dummy_class_instance.retry_block(retry_times, &test_block) }.to raise_error 'Exception: test'
      expect(dummy_class_instance).to have_received(:dummy_method).exactly(retry_times).times
    end
  end
end
