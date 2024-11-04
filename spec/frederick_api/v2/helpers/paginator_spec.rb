# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::Paginator do
  let(:data) { {} }
  let(:first_result) { FrederickAPI::V2::Resource.new }
  let(:result) { [first_result, 'b'] }
  let(:result_set) { JsonApiClient::ResultSet.new(result) }
  let(:paginator) do
    subj = described_class.new(result_set, data)
    result_set.pages = subj
    subj
  end
  let(:retry_times) { 3 }
  let(:links) { { 'first' => 'first_link' } }
  let(:eligible_page_count_val) { 5 }

  before { allow(FrederickAPI.config).to receive(:retry_times).and_return(retry_times) }

  describe 'superclass' do
    it { expect(described_class.superclass).to eq JsonApiClient::Paginating::Paginator }
  end

  describe 'class attrs' do
    it 'has right values set for class attrs' do
      expect(described_class.page_param).to eq 'number'
      expect(described_class.per_page_param).to eq 'size'
    end
  end

  describe '#total_pages' do
    before do
      expect(paginator).to receive(:links).and_return links
    end

    context 'no last link' do
      it 'current page' do
        expect(paginator.total_pages).to eq 1
      end
    end
  end

  describe '#per_page' do
    context 'no per page param' do
      it 'returns length of result set' do
        expect(paginator.per_page).to eq 2
      end
    end

    context 'per page param exists' do
      let(:params) { { 'page.size' => '5' } }

      it 'returns per page param' do
        expect(paginator).to receive(:params).and_return params
        expect(paginator.per_page).to eq 5
      end
    end
  end

  describe '#current_page' do
    it 'returns current page number' do
      expect(paginator.current_page).to eq 1
    end
  end

  describe '#all_records' do
    let(:current_page) { 2 }
    let(:total_pages) { 4 }
    let(:result2) { %w[c] }
    let(:result3) { %w[d e] }
    let(:new_result_set) do
      rs = JsonApiClient::ResultSet.new(result2)
      rs.pages = paginator
      rs
    end
    let(:new_result_set2) do
      rs = JsonApiClient::ResultSet.new(result3)
      rs.pages = paginator
      rs
    end

    context 'returns result from all pages' do
      before do
        expect(paginator).to receive(:current_page).with(no_args).and_return(current_page)
        expect(paginator).to receive(:total_pages).with(no_args).and_return(total_pages)
        expect(paginator).to receive(:next).with(no_args).and_return(new_result_set)
        expect(paginator).to receive(:next).with(no_args).and_return(new_result_set2)
      end

      it 'aggregates all the remaining pages' do
        expect(paginator.all_records).to eq(result + result2 + result3)
      end
    end

    context 'returns blank data from pages' do
      before do
        expect(paginator).to receive(:current_page).with(no_args).and_return(current_page)
        expect(paginator).to receive(:total_pages).with(no_args).and_return(total_pages)
        expect(paginator).to receive(:next).exactly(retry_times).times.with(no_args).and_return(nil)
      end

      it 'raise the next link not found' do
        expect { paginator.all_records }.to raise_error 'next link not found'
      end
    end
  end

  describe '#retry_block' do
    let(:current_page) { 1 }
    let(:total_pages) { 2 }

    context '2nd retry returns data' do
      before do
        expect(paginator).to receive(:current_page).with(no_args).and_return(current_page)
        expect(paginator).to receive(:total_pages).with(no_args).and_return(total_pages)
        expect(paginator).to receive(:next).with(no_args).and_return(nil)
        expect(paginator).to receive(:next).with(no_args).and_return(result_set)
      end

      it 'retry 2 times' do
        expect(paginator.all_records).to eq(result + result_set)
      end
    end

    context 'data is not returned after n retry' do
      before do
        expect(paginator).to receive(:current_page).with(no_args).and_return(current_page)
        expect(paginator).to receive(:total_pages).with(no_args).and_return(total_pages)
        expect(paginator).to receive(:next).with(no_args).and_return(nil)
        expect(paginator).to receive(:next).with(no_args).and_return(nil)
        expect(paginator).to receive(:next).with(no_args).and_return(nil)
      end

      it 'retries n times and raises error' do
        expect { paginator.all_records }.to raise_error 'next link not found'
      end
    end
  end

  describe '#first_link' do
    before do
      allow(paginator).to receive(:links).and_return links
    end

    it 'returns the first link' do
      expect(paginator.first_link).to eq('first_link')
    end
  end

  describe '#pages_to_be_fetched' do
    before do
      allow(paginator).to receive(:eligible_page_count).and_return eligible_page_count_val
      allow(FrederickAPI.config).to receive(:jsonapi_campaign_check_enabled).and_return(true)
      allow(paginator).to receive(:is_campaign_source?).and_return(true)
      allow(paginator).to receive(:total_pages).and_return(8)
      allow(paginator).to receive(:current_page).and_return(1)
    end

    it 'returns the min pages count value' do
      expect(paginator.pages_to_be_fetched).to eq(6)
    end
  end
end
