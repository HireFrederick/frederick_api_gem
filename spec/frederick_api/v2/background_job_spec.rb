# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::BackgroundJob do
  it_behaves_like 'v2_resource'

  describe 'class attributes' do
    describe 'read_only_attributes' do
      let(:base_read_only_attributes) { %i[id type links meta relationships] }

      it 'has right read only attributes' do
        expect(described_class.read_only_attributes).to eq base_read_only_attributes
        expect(described_class.superclass.read_only_attributes).to eq base_read_only_attributes
      end
    end
  end

  describe '#errors' do
    subject(:job) { described_class.new(status: 'error', messages: messages) }

    context 'plain-string messages, as frolodex reports a failed job' do
      let(:messages) { ['stack level too deep'] }

      it 'wraps each message as a JSON:API-style error hash so Errors::Error#to_s can show it' do
        expect(job.errors).to eq [{ 'detail' => 'stack level too deep' }]
      end
    end

    context 'a single message that is not wrapped in an array' do
      let(:messages) { 'stack level too deep' }

      it { expect(job.errors).to eq [{ 'detail' => 'stack level too deep' }] }
    end

    context 'JSON:API error objects' do
      let(:messages) { [{ 'detail' => 'boom', 'status' => '500' }] }

      it 'passes them through unchanged' do
        expect(job.errors).to eq [{ 'detail' => 'boom', 'status' => '500' }]
      end
    end

    context 'no messages' do
      let(:messages) { nil }

      it { expect(job.errors).to eq [] }
    end

    context 'a very long message (for example a SQL statement)' do
      let(:messages) { ['x' * 1_500] }

      it 'keeps the first 1,000 characters' do
        expect(job.errors.first['detail'].length).to eq 1_000
      end
    end
  end

  describe '#has_errors?' do
    it 'depends on the status only' do
      expect(described_class.new(status: 'error').has_errors?).to be true
      expect(described_class.new(status: 'processing', messages: ['x']).has_errors?).to be false
    end
  end
end
