# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Resource, :integration do
  let(:resource) { FrederickAPI::V2::User }
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
      let(:resp) do
        {
          status: 200,
          headers: {
            content_type: 'application/vnd.api+json'
          },
          body: {
            data: [
              {
                'id': id,
                'type': 'users',
                'links': {},
                'attributes': {
                  'email': 'foo@example.com'
                },
                'relationships': {}
              }
            ]
          }.to_json
        }
      end

      before do
        stub_request(:get, base_url)
          .with(headers: request_headers).to_return(resp)
      end

      it 'makes GET request' do
        resource.with_access_token(access_token) { resource.all }
        expect(
          a_request(:get, base_url)
        ).to have_been_made.once
      end

      it 'returns data' do
        expect(
          resource.with_access_token(access_token) { resource.all }.first
        ).to be_a FrederickAPI::V2::User
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

    context 'bad request error' do
      let(:resp) do
        {
          status: 400,
          headers: {
            content_type: 'application/vnd.api+json'
          },
          body: {
            'errors' => [
              {
                'title' => 'property `not_a_real_contact_property` does not exist',
                'detail' => 'properties - property `not_a_real_contact_property` does not exist',
                'code' => '100',
                'source' => { 'pointer' => '/data/attributes/properties' },
                'status' => '400'
              }
            ]
          }.to_json
        }
      end

      before do
        stub_request(:get, base_url)
          .with(headers: request_headers).to_return(resp)
      end

      it 'raises' do
        expect do
          resource.with_access_token(access_token) { resource.all }.first
        end.to raise_error FrederickAPI::V2::Errors::BadRequest
      end
    end

    context 'unprocessable entity error' do
      let(:resp) do
        {
          status: 422,
          headers: {
            content_type: 'application/vnd.api+json'
          },
          body: {
            'errors' => [
              {
                'title' => 'property `not_a_real_contact_property` does not exist',
                'detail' => 'properties - property `not_a_real_contact_property` does not exist',
                'code' => '100',
                'source' => { 'pointer' => '/data/attributes/properties' },
                'status' => '422'
              }
            ]
          }.to_json
        }
      end

      before do
        stub_request(:get, base_url)
          .with(headers: request_headers).to_return(resp)
      end

      it 'raises' do
        expect do
          resource.with_access_token(access_token) { resource.all }.first
        end.to raise_error FrederickAPI::V2::Errors::UnprocessableEntity
      end
    end

    context 'errors which should raise JsonApiClient::Errors::Error classes' do
      {
        401 => JsonApiClient::Errors::NotAuthorized,
        403 => JsonApiClient::Errors::AccessDenied,
        404 => JsonApiClient::Errors::NotFound,
        409 => JsonApiClient::Errors::Conflict,
        500 => JsonApiClient::Errors::ServerError,
        42 => JsonApiClient::Errors::UnexpectedStatus
      }.each do |response_code, error_klass|
        context "response is #{response_code}" do
          let(:resp) do
            {
              status: response_code
            }
          end

          before do
            stub_request(:get, base_url)
              .with(headers: request_headers).to_return(resp)
          end

          it 'raises' do
            expect do
              resource.with_access_token(access_token) { resource.all }.first
            end.to raise_error error_klass
          end
        end
      end
    end

    context 'long running processes' do
      let(:base_url) { 'http://test.host/v2' }
      let(:resource) { FrederickAPI::V2::Contact }
      let(:request_headers) do
        {
          'Accept': 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json'
        }
      end
      let(:location_id) { SecureRandom.uuid }
      let(:long_resource) { FrederickAPI::V2::Contact }
      let(:long_job_url) { "#{base_url}/locations/#{location_id}/contacts" }
      let(:background_base_url) { "#{base_url}/locations/#{location_id}/contacts/background_jobs" }
      let(:background_id) { SecureRandom.uuid }
      let(:background_resource_path) { "/v2/locations/#{location_id}/contacts/background_jobs/#{background_id}" }
      let(:background_resource_url) { "#{background_base_url}/#{background_id}" }
      let(:queued_attributes) do
        {
          'data': {
            'attributes': {
              'status': 'queued'
            }
          }
        }
      end
      let(:processing_attributes) do
        {
          'data': {
            'attributes': {
              'status': 'processing'
            }
          }
        }
      end
      let(:complete_attributes) do
        {
          'data': {
            'attributes': {
              'status': 'complete'
            }
          }
        }
      end
      let(:error_attributes) do
        {
          'data': {
            'attributes': {
              'status': 'error',
              'errors': [
                    'the fooborg graggled to the end, but found no nugbesters',
                    'a vorpal sword must be equipped in order to perform this action'
                  ]
            }
          }
        }
      end
      let(:background_resource_base_response_body) do
        {
          'data': {
            'type': 'background_jobs',
            'id': background_id,
            'links': {
              'self': background_resource_path
            }
          }
        }
      end

      let(:background_resource_202_response) do
        {
          status: 202,
          headers: {
            'Content-Type': 'application/vnd.api+json',
            'Content-Location': background_resource_url
          },
          body: background_resource_base_response_body.deep_merge(queued_attributes).to_json
        }
      end

      let(:background_resource) do
        {
          status: 200,
          headers: {
            'Content-Type': 'application/vnd.api+json',
            'Retry-After': 42
          },
          body: background_resource_base_response_body.deep_merge(processing_attributes).to_json
        }
      end

      let(:background_resource_error_response) do
        {
          status: 202,
          headers: {
            'Content-Type': 'application/vnd.api+json',
            'Content-Location': background_resource_url
          },
          body: background_resource_base_response_body.deep_merge(error_attributes).to_json
        }
      end

      let(:background_resource_complete_response) do
        {
          status: 202,
          headers: {
            'Content-Type': 'application/vnd.api+json',
            'Content-Location': background_resource_url
          },
          body: background_resource_base_response_body.deep_merge(complete_attributes).to_json
        }
      end

      let(:real_payload_url) { "#{long_job_url}/background_jobs/#{background_id}/real_payload" }
      let(:redirect_to_real_payload) { { status: 303, headers: { 'Location': real_payload_url } } }
      let(:real_payload) do
        {
          status: 200,
          headers: {
            'Content-Type': 'application/vnd.api+json'
          },
          body: {
            data: {
              type: 'contacts',
              attributes: {
                foo: 'bar'
              }
            }
          }.to_json
        }
      end

      context 'when successful' do
        before do
          stub_request(:post, long_job_url)
              .to_return(background_resource_202_response)
          stub_request(:get, background_resource_url)
              .to_return(background_resource).then
              .to_return(background_resource).then
              .to_return(redirect_to_real_payload)
          stub_request(:get, real_payload_url).to_return(real_payload)
          allow_any_instance_of(FrederickAPI::V2::Helpers::Requestor).to receive(:sleep).with(1)
          allow_any_instance_of(FrederickAPI::V2::Helpers::Requestor).to receive(:sleep).with(42)
        end

        it 'follows 202 Location' do
          expect(resource.where(location_id: location_id).all)
              .to have_requested(:get, background_resource_url).at_least_times(1)
        end

        it 'polls for completion' do
          expect(resource.where(location_id: location_id).all)
            .to have_requested(:get, background_resource_url)
            .at_least_times(2)
        end
        it 'respects the retry-after header' do
          expect_any_instance_of(FrederickAPI::V2::Helpers::Requestor).to receive(:sleep).exactly(3).times
          resource.where(location_id: location_id).all
        end
        it 'follows 303' do
          expect(resource.where(location_id: location_id).all)
              .to have_requested(:get, real_payload_url)
        end
        it 'returns completed resource' do
          expect(resource.where(location_id: location_id).all.first.attributes['foo'])
              .to eq('bar')
        end
      end
      context 'when errors happen' do
        before do
          stub_request(:post, long_job_url)
              .to_return(background_resource_error_response)
        end
        it 'raises a BackgroundJobFailure exception' do
          expect do
            resource.where(location_id: location_id).all
          end.to raise_error(FrederickAPI::V2::Errors::BackgroundJobFailure)
        end
      end
      context 'when complete, with no response' do
        before do
          stub_request(:post, long_job_url)
            .to_return(background_resource_complete_response)
        end
        it 'returns the BackgoundJob resource' do
          expect(resource.where(location_id: location_id).all.first)
              .to be_kind_of(FrederickAPI::V2::BackgroundJob)
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

  describe 'has_many association' do
    let(:resource) { FrederickAPI::V2::ContactList }

    before do
      stub_request(:get, 'http://test.host/v2/locations/123/contact_lists?page.number=1&page.size=1')
        .to_return(headers: { content_type: 'application/vnd.api+json' }, body: {
          data: [
            {
              id: 1,
              attributes: {
                name: 'all_contacts',
              },
              relationships: {
                contacts: {
                  links: {
                    self: 'http://test.host/v2/locations/123/contact_lists/relationships/contacts',
                    related: 'http://test.host/v2/locations/123/contact_lists/contacts'
                  }
                }
              }
            }
          ]
        }.to_json)
      stub_request(:get, 'http://test.host/v2/locations/123/contact_lists/contacts')
        .with(headers: { 'Accept' => 'application/vnd.api+json',
                         'Content-Type' => 'application/vnd.api+json', 'X-Api-Key' => '1234-5678-8765-4321' })
        .to_return(status: 200, headers: { content_type: 'application/vnd.api+json' }, body: {
          data: [
            {
              id: 1,
              attributes: {
                name: 'contact one',
              }
            }
          ]
        }.to_json)
    end

    it 'returns query builder' do
      list = resource.where(location_id: '123').first
      query_builder = list.contacts
      expect(query_builder).to be_a FrederickAPI::V2::Helpers::QueryBuilder
      first_contact = query_builder.all.first
      expect(first_contact).to be_a FrederickAPI::V2::Contact
      expect(first_contact.name).to eq 'contact one'
    end
  end
end
