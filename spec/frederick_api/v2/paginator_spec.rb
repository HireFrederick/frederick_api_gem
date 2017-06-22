# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Paginator do
  let(:data) { {} }
  let(:first_result) { FrederickAPI::V2::Resource.new }
  let(:result) { [first_result, 'b'] }
  let(:result_set) { JsonApiClient::ResultSet.new(result) }
  let(:paginator) do
    subj = described_class.new(result_set, data)
    result_set.pages = subj
    subj
  end

  describe 'superclass' do
    it { expect(described_class.superclass).to eq JsonApiClient::Paginating::Paginator }
  end

  describe 'class attrs' do
    it 'has right values set for class attrs' do
      expect(described_class.page_param).to eq 'page.number'
      expect(described_class.per_page_param).to eq 'page.size'
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

    # rubocop:disable RSpec/MessageSpies
    before do
      expect(paginator).to receive(:current_page).with(no_args).and_return(current_page)
      expect(paginator).to receive(:total_pages).with(no_args).and_return(total_pages)
      expect(paginator).to receive(:next).with(no_args).and_return(new_result_set)
      expect(paginator).to receive(:next).with(no_args).and_return(new_result_set2)
    end
    # rubocop:enable RSpec/MessageSpies

    it 'aggregates all the remaining pages' do
      expect(paginator.all_records).to eq(result + result2 + result3)
    end
  end
end
