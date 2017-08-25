# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::QueryBuilder do
  let(:query_builder) { described_class.new('klass') }

  describe '#params' do
    let(:result) do
      {
        'filter.name' => 'covfefe',
        'page.number' => 2,
        'page.size' => 30,
        'includes' => 'packages',
        'fields.billing_contacts' => 'title,body',
        sort: 'age'
      }
    end

    before do
      allow(query_builder).to receive(:filter_params).and_return(filter: { name: 'covfefe' })
      allow(query_builder).to receive(:pagination_params).and_return(page: { number: 2, size: 30 })
      allow(query_builder).to receive(:order_params).and_return(sort: 'age')
      allow(query_builder).to receive(:includes_params).and_return(includes: 'packages')
      allow(query_builder).to receive(:select_params).and_return(fields: { 'billing_contacts' => 'title,body' })
    end

    it 'returns correct hash' do
      expect(query_builder.params).to eq result
    end
  end

  describe '#filter_params' do
    let(:filter_array) { ['b', 1] }
    let(:filters) { { foo: 'bar', c: true, a: filter_array } }
    let(:query_builder) { FrederickAPI::V2::User.where(filters) }

    it 'transforms arrays into comma delimited strings' do
      expect(query_builder.filter_params).to eq(filter: filters.merge(a: filter_array.join(',')))
    end
  end

  describe '#all_records' do
    let(:result_set) { JsonApiClient::ResultSet.new }
    let(:paginator) { FrederickAPI::V2::Helpers::Paginator.new(result_set, {}) }
    let(:all_records) { 'all_records' }

    after { expect(query_builder.all_records).to eq all_records }

    it 'call right method chain' do
      expect(query_builder).to receive(:all).with(no_args).and_return(result_set).ordered
      expect(result_set).to receive(:pages).with(no_args).and_return(paginator).ordered
      expect(paginator).to receive(:all_records).with(no_args).and_return(all_records).ordered
    end
  end

  describe '#to_dot_params' do
    let(:filter_params) { { filter: { name: 'name' } } }
    let(:sort_params) { { page: { number: 2, size: 30 } } }
    let(:select_params) { { fields: { 'billing_contacts' => 'title,body' } } }

    it 'returns correct serializations' do
      expect(query_builder.to_dot_params(filter_params)).to eq('filter.name' => 'name')
      expect(query_builder.to_dot_params(sort_params)).to eq('page.number' => 2, 'page.size' => 30)
      expect(query_builder.to_dot_params(select_params)).to eq('fields.billing_contacts' => 'title,body')
    end
  end
end
