# frozen_string_literal: true

require 'spec_helper'

module FrederickAPI::V2
  RSpec.describe Resource, :integration do
    let(:resource) do
      Class.new(Resource) do
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
        let(:id) { SecureRandom.uuid }
        let(:id2) { SecureRandom.uuid }
        let(:id3) { SecureRandom.uuid }
        let(:email) { 'user_email@gmail.com' }
        let(:email2) { 'user_email2@gmail.com' }
        let(:email3) { 'user_email3@gmail.com' }
        let(:last_link) { "#{base_url}?page.number=3&page.size=1" }
        let(:next_link_obj) { { 'next': last_link } }
        let(:links) do
          {
            'last': last_link
          }.merge(next_link_obj)
        end
        let(:user_resp) do
          {
            'id': id,
            'type': 'users',
            'links': {},
            'attributes': {
              'email': email
            },
            'relationships': {}
          }
        end
        let(:user_resp2) do
          user_resp.merge('id': id2, 'attributes': { 'email': email2 })
        end
        let(:user_resp3) do
          user_resp.merge('id': id3, 'attributes': { 'email': email3 })
        end
        let(:body) { { "data": [user_resp], "links": links }.to_json }
        let(:body2) { { "data": [user_resp2, user_resp3], "links": links }.to_json }
        let(:base_resp) { { status: 200, headers: { content_type: 'application/vnd.api+json' } } }
        let(:result) do
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

        before do
          stub_request(:get, "#{base_url}?#{query_params}")
            .with(headers: request_headers).to_return(base_resp.merge(body: body))
        end

        context 'all records not called on result set' do
          it 'makes request with correct query params format' do
            result
            expect(a_request(:get, "#{base_url}?#{query_params}")).to have_been_made.once
            expect(a_request(:get, last_link)).not_to have_been_made
          end

          it 'returns right parsed resp' do
            expect(result.length).to eq 1

            expect(result.first.class).to eq resource
            expect(result.first.id).to eq id
            expect(result.first.email).to eq email
          end
        end

        context 'all records called on result set' do
          let(:pagination_result) { result.pages.all_records }

          before do
            stub_request(:get, last_link)
              .with(headers: request_headers)
              .to_return(base_resp.merge(body: body2))
          end

          it 'makes request with correct query params format' do
            pagination_result
            expect(a_request(:get, "#{base_url}?#{query_params}")).to have_been_made.once
            expect(a_request(:get, last_link)).to have_been_made.once
          end

          it 'returns right parsed resp' do
            expect(pagination_result.length).to eq 3
            pagination_result.each { |bc| expect(bc.class).to eq resource }

            expect(pagination_result.first.id).to eq id
            expect(pagination_result.first.email).to eq email

            expect(pagination_result.second.id).to eq id2
            expect(pagination_result.second.email).to eq email2

            expect(pagination_result.third.id).to eq id3
            expect(pagination_result.third.email).to eq email3
          end

          context 'next link not found' do
            let(:next_link_obj) { {} }

            it 'raises, does not make next request' do
              expect { pagination_result }.to raise_error(StandardError, 'next link not found')
              expect(a_request(:get, "#{base_url}?#{query_params}")).to have_been_made.once
              expect(a_request(:get, last_link)).not_to have_been_made
            end
          end
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
