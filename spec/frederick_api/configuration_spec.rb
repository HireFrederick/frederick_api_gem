# frozen_string_literal: true

require 'spec_helper'

module FrederickAPI
  RSpec.describe Configuration do
    let(:example_base_url) { 'https://api.fakefrederick.example.com' }
    let(:example_public_base_url) { 'https://api.public.fakefrederick.example.com' }
    let(:example_api_key) { '1234-4567-1234-5678' }
    let(:example_retry_times) { 3 }
    let(:example_jsonapi_campaign_check_enabled) { 'false' }
    let(:example_emails_per_day_limit) { 2000 }
    let(:example_frolodex_batch_fetch_size) { 2000 }
    let(:example_emails_per_day_limit_enabled) { 'true' }
    let!(:prev_config) { FrederickAPI.config.dup }

    after { FrederickAPI.config = prev_config }

    describe 'FrederickAPI.configure' do
      before do
        FrederickAPI.configure do |c|
          c.base_url = example_base_url
          c.public_base_url = example_public_base_url
          c.api_key = example_api_key
          c.retry_times = example_retry_times
          c.jsonapi_campaign_check_enabled = example_jsonapi_campaign_check_enabled
          c.emails_per_day_limit = example_emails_per_day_limit
          c.frolodex_batch_fetch_size = example_frolodex_batch_fetch_size
          c.emails_per_day_limit_enabled = example_emails_per_day_limit_enabled
        end
      end

      it 'sets @base_url' do
        expect(FrederickAPI.config.base_url).to eq example_base_url
      end

      it 'sets @public_base_url' do
        expect(FrederickAPI.config.public_base_url).to eq example_public_base_url
      end

      it 'sets @api_key' do
        expect(FrederickAPI.config.api_key).to eq '1234-4567-1234-5678'
      end

      it 'sets @retry_times' do
        expect(FrederickAPI.config.retry_times).to eq example_retry_times
      end

      it 'sets @jsonapi_campaign_check_enabled' do
        expect(FrederickAPI.config.jsonapi_campaign_check_enabled).to eq example_jsonapi_campaign_check_enabled
      end

      it 'sets @emails_per_day_limit' do
        expect(FrederickAPI.config.emails_per_day_limit).to eq example_emails_per_day_limit
      end

      it 'sets @frolodex_batch_fetch_size' do
        expect(FrederickAPI.config.frolodex_batch_fetch_size).to eq example_frolodex_batch_fetch_size
      end

      it 'sets @emails_per_day_limit_enabled' do
        expect(FrederickAPI.config.emails_per_day_limit_enabled).to eq example_emails_per_day_limit_enabled
      end
    end
  end

  # TODO: backfill specs for ENV-based defaults
end
