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
  let(:links) { JsonApiClient::Linking::TopLevelLinks.new(
    FrederickAPI::V2::Resource,
    {
    'first'=>'https://testlinks.com/?page.number=1&page.size=10', 
    'last'=> 'https://testlinks.com/?page.number=8&page.size=10'
    }
    )
  }
  let(:retry_times) { 3 }

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
   
    context 'with last links' do
      before do
        expect(result_set).to receive(:links).twice.and_return links
      end
      
      it 'returns current page from last link' do
        expect(paginator.total_pages).to eq 8
      end
    end

    context 'no last link' do
      before do
        expect(result_set).to receive(:links).and_return nil
      end

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
        expect(paginator.all_records).to eq(result+result_set)
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
end
