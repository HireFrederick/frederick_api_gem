# frozen_string_literal: true

require 'spec_helper'

module FrederickApi
  RSpec.describe Configuration do
    let(:example_base_url) { 'https://api.fakefrederick.example.com' }
    let(:example_api_key) { '1234-4567-1234-5678' }
    let!(:prev_config) { FrederickApi.config.dup }

    after { FrederickApi.config = prev_config }

    describe 'FrederickApi.configure' do
      before do
        FrederickApi.configure do |c|
          c.base_url = example_base_url
          c.api_key = example_api_key
        end
      end

      it 'sets @base_url' do
        expect(FrederickApi.config.base_url).to eq example_base_url
      end

      it 'sets @api_key' do
        expect(FrederickApi.config.api_key).to eq '1234-4567-1234-5678'
      end
    end
  end
end
