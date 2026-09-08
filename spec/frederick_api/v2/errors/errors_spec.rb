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

  describe BadRequest do
    subject { described_class.new(FrederickAPI::V2::Resource.new) }

    it { is_expected.to be_a(Error) }
  end

  describe UnprocessableEntity do
    subject { described_class.new(FrederickAPI::V2::Resource.new) }

    it { is_expected.to be_a(Error) }
  end

  describe RateLimited do
    let(:headers) { {} }
    let(:env) { OpenStruct.new(status: 429, url: 'http://test.host/foo', response_headers: headers) }
    let(:error) { described_class.new(env) }

    it 'is a JsonApiClient client error' do
      expect(described_class.superclass).to eq JsonApiClient::Errors::ClientError
    end

    it 'names the status and the url' do
      expect(error.message).to eq '429 Too Many Requests: http://test.host/foo'
      expect(error.env).to be env
    end

    describe '#retry_after' do
      context 'no Retry-After header' do
        it { expect(error.retry_after).to be_nil }
      end

      context 'Retry-After in seconds' do
        let(:headers) { { 'Retry-After' => '7' } }

        it { expect(error.retry_after).to eq 7 }
      end

      context 'Retry-After as an HTTP date in the future' do
        let(:headers) { { 'Retry-After' => (Time.now + 30).httpdate } }

        it 'returns the whole seconds until that time' do
          expect(error.retry_after).to be_between(28, 30)
        end
      end

      context 'Retry-After as an HTTP date in the past' do
        let(:headers) { { 'Retry-After' => 'Wed, 21 Oct 2015 07:28:00 GMT' } }

        it { expect(error.retry_after).to eq 0 }
      end

      context 'Retry-After that is neither seconds nor a date' do
        let(:headers) { { 'Retry-After' => 'soon' } }

        it { expect(error.retry_after).to be_nil }
      end

      context 'blank Retry-After' do
        let(:headers) { { 'Retry-After' => ' ' } }

        it { expect(error.retry_after).to be_nil }
      end
    end
  end
end
