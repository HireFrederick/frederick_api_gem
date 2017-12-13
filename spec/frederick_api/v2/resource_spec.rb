# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Resource do
  let(:subclass) { FrederickAPI::V2::User }
  let(:instance) { subclass.new }

  describe 'superclass' do
    it 'inherits from JsonApiClient::Resource' do
      expect(described_class.superclass).to eq JsonApiClient::Resource
    end
  end

  describe '.query_builder' do
    it 'FrederickAPI::V2::Helpers::QueryBuilder' do
      expect(described_class.query_builder).to be FrederickAPI::V2::Helpers::QueryBuilder
    end
  end

  describe '.paginator' do
    it 'FrederickAPI::V2::Helpers::Paginator' do
      expect(described_class.paginator).to be FrederickAPI::V2::Helpers::Paginator
    end
  end

  describe '.requestor_class' do
    it 'FrederickAPI::V2::Helpers::Requestor' do
      expect(described_class.requestor_class).to be FrederickAPI::V2::Helpers::Requestor
    end
  end

  describe 'methods' do
    it 'responds to #create' do
      expect(subclass).to respond_to('create')
    end
    it 'responds to #find' do
      expect(subclass).to respond_to('find')
    end
    it 'responds to #all' do
      expect(subclass).to respond_to('all')
    end
    it 'responds to #where' do
      expect(subclass).to respond_to('where')
    end
  end

  describe '#has_errors?' do
    context 'no errors' do
      it 'false' do
        expect(instance.has_errors?).to be false
      end
    end

    context 'with errors' do
      before { allow(instance).to receive(:errors).and_return 'some errors' }

      it 'true' do
        expect(instance.has_errors?).to be true
      end
    end
  end

  describe '.all_records' do
    let(:result_set) { JsonApiClient::ResultSet.new }
    let(:paginator) { FrederickAPI::V2::Helpers::Paginator.new(result_set, {}) }
    let(:all_records) { 'all_records' }

    after { expect(subclass.all_records).to eq all_records }

    it 'call right method chain' do
      expect(subclass).to receive(:all).with(no_args).and_return(result_set).ordered
      expect(result_set).to receive(:pages).with(no_args).and_return(paginator).ordered
      expect(paginator).to receive(:all_records).with(no_args).and_return(all_records).ordered
    end
  end

  describe '.top_level_namespace' do
    it 'eqs right constant' do
      expect(subclass.top_level_namespace).to eq FrederickAPI
    end
  end

  describe '.custom_headers' do
    before { allow(subclass).to receive(:_header_store).and_return(existing: 'headers') }

    it 'merges api key' do
      expect(subclass.custom_headers[:x_api_key]).to eq('1234-5678-8765-4321')
      expect(subclass.custom_headers[:existing]).to eq('headers')
    end
  end

  describe '.site' do
    context 'config base_url is set' do
      it 'is assigned correctly' do
        expect(described_class.site).to eq 'http://test.host/v2/'
      end
    end
  end

  describe '._header_store' do
    it '{} by default' do
      expect(described_class._header_store).to eq({})
    end

    context 'thread current present' do
      before { Thread.current['frederick_api_header_store'] = { foo: 'bar' } }
      after { Thread.current['frederick_api_header_store'] = nil }

      it 'thread current' do
        expect(described_class._header_store).to eq(foo: 'bar')
      end
    end
  end
end
