# frozen_string_literal: true

require 'spec_helper'

module FrederickApi::V2::Models
  RSpec.describe BaseResource, :integration do
    let(:resource) do
      Class.new(BaseResource) do
        def self.name
          'User'
        end
      end
    end
    let(:first_name) { 'user' }
    let(:updated_first_name) { 'user_2' }
    let(:attributes) { { first_name: first_name } }
    let(:base_url) { 'http://test.host/v2/users' }
    let(:id) { 1234 }
    let(:url_with_id) { "#{base_url}/#{id}" }
    let(:request_body) { "{\"data\":{\"type\":\"users\",\"attributes\":{\"first_name\":\"#{first_name}\"}}}" }
    let(:update_body) do
      "{\"data\":{\"id\":1234,\"type\":\"users\",\"attributes\":{\"first_name\":\"#{updated_first_name}\"}}}"
    end
    let(:access_token) { 'the token' }
    let(:request_headers) do
      {
        'Accept': 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json',
        'X-Api-Key': '1234-5678-8765-4321',
        'Authorization': "Bearer #{access_token}"
      }
    end

    before do
      WebMock.reset!
    end

    describe 'POST' do
      before do
        stub_request(:post, base_url)
          .with(body: request_body,
                headers: request_headers)
        resource.with_access_token(access_token) { resource.create(attributes) }
      end

      it 'makes request' do
        expect(
          a_request(:post, base_url)
        ).to have_been_made.once
      end
    end

    describe 'GET index' do
      context 'with no query params' do
        before do
          stub_request(:get, base_url)
            .with(headers: request_headers)
          resource.with_access_token(access_token) { resource.all }
        end

        it 'makes GET request' do
          expect(
            a_request(:get, base_url)
          ).to have_been_made.once
        end
      end

      context 'with query params' do
        let(:query_params) do
          [
            'fields.users=first_name&',
            "filter.first_name=#{first_name}&",
            'include=permitted_locations&',
            'page.number=2&',
            'page.size=30&',
            'sort=created_at'
          ].join
        end

        before do
          stub_request(:get, "#{base_url}?#{query_params}")
            .with(headers: request_headers)
          resource.with_access_token(access_token) do
            resource.where(first_name: first_name)
                    .page(2)
                    .per(30)
                    .order('created_at')
                    .select('first_name')
                    .includes(:permitted_locations)
                    .all
          end
        end

        it 'makes request with correct query params format' do
          expect(
            a_request(:get, "#{base_url}?#{query_params}")
          ).to have_been_made.once
        end
      end
    end

    describe 'PATCH' do
      before do
        stub_request(:patch, url_with_id)
          .with(body: update_body,
                headers: request_headers)
        resource.with_access_token(access_token) do
          user = resource.new(attributes.merge(id: id))
          user.mark_as_persisted!
          user.update_attributes(first_name: updated_first_name)
        end
      end

      it 'makes PATCH request' do
        expect(
          a_request(:patch, "#{base_url}/#{id}")
        ).to have_been_made.once
      end
    end

    describe 'GET' do
      before do
        stub_request(:get, url_with_id)
          .with(headers: request_headers)
        resource.with_access_token(access_token) { resource.find(id) }
      end

      it 'makes GET request' do
        expect(
          a_request(:get, "#{base_url}/#{id}")
        ).to have_been_made.once
      end
    end
  end
end
