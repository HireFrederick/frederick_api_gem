# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Errors do
  it 'ERROR_CODES' do
    expect(described_class::ERROR_CODES).to eq(
      '400' => FrederickAPI::V2::Errors::BadRequest,
      '422' => FrederickAPI::V2::Errors::UnprocessableEntity
    )
  end
end

module FrederickAPI::V2::Errors
  describe Error do
    let(:result) { FrederickAPI::V2::Resource.new }
    let(:instance) { described_class.new(result) }
    let(:errors) { 'the errors' }

    before do
      allow(result).to receive(:errors).and_return errors
    end

    describe '#initialize' do
      context 'result has errors' do
        it 'sets env and errors' do
          expect(instance.errors).to be errors
          expect(instance.env).to be result
        end
      end

      context 'result does not have errors' do
        let(:errors) { nil }

        it 'sets env and errors' do
          expect(instance.errors).to eq []
          expect(instance.env).to be result
        end
      end
    end
  end

  describe Error, '#to_s' do
    let(:result) { FrederickAPI::V2::Resource.new }

    it 'shows the detail of a JSON:API error object' do
      allow(result).to receive(:errors).and_return(
        JsonApiClient::ErrorCollector.new([{ 'detail' => 'Name is required' }])
      )
      expect(described_class.new(result).message).to eq 'Client Error: Name is required'
    end
  end

  describe BadRequest do
    subject { described_class.new(FrederickAPI::V2::Resource.new) }

    it { is_expected.to be_a(Error) }
  end

  describe BackgroundJobFailure do
    it { expect(described_class.new(FrederickAPI::V2::Resource.new)).to be_a(Error) }

    context 'a background job that frolodex marked as failed with plain-string messages' do
      let(:job) { FrederickAPI::V2::BackgroundJob.new(status: 'error', messages: ['stack level too deep']) }
      let(:error) { described_class.new(job) }

      it 'names the reason instead of an empty "Client Error: " message (AB#1284255)' do
        expect(error.message).to eq 'Client Error: stack level too deep'
        expect(error.errors).to eq [{ 'detail' => 'stack level too deep' }]
        expect(error.env).to be job
      end
    end

    context 'a background job that failed with JSON:API error objects' do
      let(:job) { FrederickAPI::V2::BackgroundJob.new(status: 'error', messages: [{ 'detail' => 'boom' }]) }

      it { expect(described_class.new(job).message).to eq 'Client Error: boom' }
    end
  end

  describe UnprocessableEntity do
    subject { described_class.new(FrederickAPI::V2::Resource.new) }

    it { is_expected.to be_a(Error) }
  end
end
