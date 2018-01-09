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
end
