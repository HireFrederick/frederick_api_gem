# frozen_string_literal: true

require 'spec_helper'

module FrederickAPI
  RSpec.describe Configuration do
    let(:example_base_url) { 'https://api.fakefrederick.example.com' }
    let(:example_public_base_url) { 'https://api.public.fakefrederick.example.com' }
    let(:example_api_key) { '1234-4567-1234-5678' }
    let!(:prev_config) { FrederickAPI.config.dup }

    after { FrederickAPI.config = prev_config }

    describe 'FrederickAPI.configure' do
      before do
        FrederickAPI.configure do |c|
          c.base_url = example_base_url
          c.public_base_url = example_public_base_url
          c.api_key = example_api_key
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
        expect(FrederickAPI.config.retry_times).to eq '1234-4567-1234-5678'
      end

      it 'sets @jsonapi_campaign_check_enabled' do
        expect(FrederickAPI.config.jsonapi_campaign_check_enabled).to eq '1234-4567-1234-5678'
      end

      it 'sets @emails_per_day_limit' do
        expect(FrederickAPI.config.emails_per_day_limit).to eq '1234-4567-1234-5678'
      end

      it 'sets @frolodex_batch_fetch_size' do
        expect(FrederickAPI.config.frolodex_batch_fetch_size).to eq '1234-4567-1234-5678'
      end

      it 'sets @emails_per_day_limit_enabled' do
        expect(FrederickAPI.config.emails_per_day_limit_enabled).to eq '1234-4567-1234-5678'
      end
    end
  end

  # TODO: backfill specs for ENV-based defaults
end
