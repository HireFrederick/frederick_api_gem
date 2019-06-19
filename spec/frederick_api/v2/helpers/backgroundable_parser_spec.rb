# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::BackgroundableParser do
  let(:backgroundable_resource_klass) do
    class FrederickAPI::V2::Background < ::FrederickAPI::V2::Resource
    end
    FrederickAPI::V2::Background
  end
  let(:response) { instance_double(Faraday::Response) }
  let(:result_set) { JsonApiClient::ResultSet.new(result) }

  describe 'superclass' do
    it { expect(described_class.superclass).to eq ::JsonApiClient::Parsers::Parser }
  end

  describe '#parse' do
    before do
      allow(response).to receive(:status).and_return(status)
      allow(response).to receive(:headers).and_return(headers)
      allow(response).to receive(:body).and_return(body)
      allow(response).to receive(:env).and_return({})
    end

    context 'when a non-background job response is received' do
      let(:status) { 200 }
      let(:headers) do
        {
          content_type: 'application/vnd.api+json'
        }
      end
      let(:body) do
        {
          'data' => {
            'type' => 'backgrounds',
            'id' => '00000000-0000-0000-0000-000000000000',
            'attributes' => {
              'an_attribute' => 'blahblah'
            },
            'links' => {
              'self' => 'https://api.foo.bar/v2/locations/11111111-1111-1111-1111-111111111111/backgrounds/11111111-1111-1111-1111-111111111111'
            }
          }
        }
      end

      let(:result) { described_class.parse(backgroundable_resource_klass, response) }

      it 'returns a normal response of the correct resource type' do
        expect(result).to be_an_instance_of(JsonApiClient::ResultSet)
        expect(result.length).to eq(1)
        expect(result.first).to be_an_instance_of(FrederickAPI::V2::Background)
      end
    end

    context 'when a non-background job response is received' do
      let(:status) { 200 }
      let(:headers) do
        {
          content_type: 'application/vnd.api+json'
        }
      end
      let(:body) do
        {
          'data' => {
            'type' => 'backgrounds',
            'id' => '00000000-0000-0000-0000-000000000000',
            'attributes' => {
              'an_attribute' => 'blahblah'
            },
            'links' => {
              'self' => 'https://api.foo.bar/v2/locations/11111111-1111-1111-1111-111111111111/backgrounds/11111111-1111-1111-1111-111111111111'
            }
          }
        }
      end

      let(:result) { described_class.parse(backgroundable_resource_klass, response) }

      it 'returns a normal response of the correct resource type' do
        expect(result).to be_an_instance_of(JsonApiClient::ResultSet)
        expect(result.length).to eq(1)
        expect(result.first).to be_an_instance_of(FrederickAPI::V2::Background)
      end
    end

    context 'when a background job response is received' do
      let(:status) { 202 }
      let(:headers) do
        {
          content_type: 'application/vnd.api+json',
          content_location: 'https://api.foo.bar/v2/locations/11111111-1111-1111-1111-111111111111/background_jobs/11111111-1111-1111-1111-111111111111'
        }
      end
      let(:body) do
        {
          'data' => {
            'type' => 'background_jobs',
            'id' => '00000000-0000-0000-0000-000000000000',
            'attributes' => {
              'an_attribute' => 'blahblah'
            },
            'links' => {
              'self' => 'https://api.foo.bar/v2/locations/11111111-1111-1111-1111-111111111111/background_jobs/11111111-1111-1111-1111-111111111111'
            }
          }
        }
      end
      let(:result) { described_class.parse(backgroundable_resource_klass, response) }

      it 'returns a normal response of the correct resource type' do
        expect(result).to be_an_instance_of(JsonApiClient::ResultSet)
        expect(result.length).to eq(1)
        expect(result.first).to be_an_instance_of(FrederickAPI::V2::BackgroundJob)
      end
    end
  end
end
