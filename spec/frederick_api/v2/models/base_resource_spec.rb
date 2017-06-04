# frozen_string_literal: true

require 'spec_helper'

module FrederickApi::V2::Models
  RSpec.describe BaseResource do
    let(:subclass) do
      Class.new(BaseResource)
    end
    let(:instance) { subclass.new }

    describe 'superclass' do
      it 'inherits from JsonApiClient::Resource' do
        expect(described_class.superclass).to eq JsonApiClient::Resource
      end
    end

    describe '.query_builder' do
      it 'FrederickApi::Utils::JsonApiQueryBuilder' do
        expect(described_class.query_builder).to be FrederickApi::Utils::JsonApiQueryBuilder
      end
    end

    describe 'methods' do
      it 'responds to #create' do
        expect(BaseResource).to respond_to('create')
      end
      it 'responds to #find' do
        expect(BaseResource).to respond_to('find')
      end
      it 'responds to #all' do
        expect(BaseResource).to respond_to('all')
      end
      it 'responds to #where' do
        expect(BaseResource).to respond_to('where')
      end
    end

    describe '.custom_headers' do
      before { allow(subclass).to receive(:_header_store).and_return(existing: 'headers') }

      it 'merges api key' do
        expect(subclass.custom_headers[:x_api_key]).to eq('1234-5678-8765-4321')
      end
    end

    describe '@@site' do
      context 'config base_url is set' do
        it 'is assigned correctly' do
          expect(described_class.site).to eq 'http://test.host/v2/'
        end
      end
    end
  end
end
