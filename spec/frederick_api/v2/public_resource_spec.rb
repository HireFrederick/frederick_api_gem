# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::PublicResource do
  let(:subclass) { FrederickAPI::V2::BusinessCategory }
  let(:instance) { subclass.new }

  describe 'superclass' do
    it 'inherits from JsonApiClient::Resource' do
      expect(described_class.superclass).to eq FrederickAPI::V2::Resource
    end
  end

  describe '.site' do
    context 'config base_url is set' do
      it 'is assigned correctly' do
        expect(described_class.site).to eq 'http://public.test.host/v2/'
      end
    end
  end
end
