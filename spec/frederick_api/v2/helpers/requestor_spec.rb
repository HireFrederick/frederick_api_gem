# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::Requestor do
  let(:superklass) { JsonApiClient::Query::Requestor }
  let(:resource) { FrederickAPI::V2::Contact }
  let(:requestor) { described_class.new(resource) }

  it 'has right superclass' do
    expect(described_class.superclass).to eq superklass
  end

  describe '#initialize' do
    let(:requestor) { described_class.new(resource, '/foo') }

    it 'sets path' do
      expect(requestor.path).to eq '/foo'
    end
  end

  describe '#resource_path' do
    let(:params) { { location_id: '123' } }

    it 'returns resource path' do
      expect(requestor.resource_path(params)).to eq 'locations/123/contacts'
    end

    context 'id in params' do
      let(:params) { { location_id: '123', id: '456' } }

      it 'returns resource path' do
        expect(requestor.resource_path(params)).to eq 'locations/123/contacts/456'
      end
    end

    context 'path passed in' do
      let(:requestor) { described_class.new(resource, '/foo') }

      it 'path' do
        expect(requestor.resource_path(params)).to eq '/foo'
      end
    end
  end

  describe '#get' do
    let(:path) { 'locations/foo/contact_types' }
    let(:params) { { the: 'params', id: 'foo' } }
    let(:response) { 'resp' }

    before do
      allow(requestor).to receive(:resource_path).and_return path
      allow(requestor).to receive(:request).and_return response
    end

    it 'gets response' do
      expect(requestor.get).to be response
      expect(requestor).to have_received(:request).with(:get, path, {})
    end

    context 'with params' do
      it 'gets response without primary key in params' do
        expect(requestor.get(params)).to be response
        expect(requestor).to have_received(:request).with(:get, path, params.except(:id))
      end
    end

    context 'path matches GET_VIA_POST_PATHS' do
      let(:headers) { { 'X-Request-Method' => 'GET' } }

      %w[locations/foo/contacts locations/foo/interactions].each do |p|
        context "path is #{p}" do
          let(:path) { p }

          it 'posts to get response without primary key in params' do
            expect(requestor.get(params)).to be response
            expect(requestor).to have_received(:request).with(:post, path, params.except(:id), headers)
          end
        end
      end
    end
  end

  describe '#linked' do
    let(:url) { 'http://foo.com/locations/foo/contact_types?foo=bar&hey=yay' }
    let(:response) { 'resp' }

    before do
      allow(requestor).to receive(:request).and_return response
    end

    it 'gets response' do
      expect(requestor.linked(url)).to be response
      expect(requestor).to have_received(:request).with(:get, url, {})
    end

    context 'url matches GET_VIA_POST_PATHS' do
      let(:headers) { { 'X-Request-Method' => 'GET' } }

      %w[http://foo.com/locations/foo/contacts http://foo.com/locations/foo/interactions].each do |p|
        context "url is #{p}" do
          let(:url) { p }
          let(:path) do
            u = URI.parse(p)
            "#{u.scheme}://#{u.host}#{u.path}"
          end
          let(:expected_params) { {} }

          it 'posts to get response without primary key in params' do
            expect(requestor.linked(url)).to be response
            expect(requestor).to have_received(:request).with(:post, path, expected_params, headers)
          end
        end

        context "url is #{p} with params" do
          let(:url) { "#{p}?foo=bar&hey=yay" }
          let(:expected_params) { { 'foo' => 'bar', 'hey' => 'yay' } }
          let(:path) do
            u = URI.parse(p)
            "#{u.scheme}://#{u.host}#{u.path}"
          end

          it 'posts to get response without primary key in params' do
            expect(requestor.linked(url)).to be response
            expect(requestor).to have_received(:request).with(:post, path, expected_params, headers)
          end
        end
      end
    end
  end

  describe '#request' do
    let(:error) {}
    let(:type) { 'type' }
    let(:path) { 'path' }
    let(:params) { 'param' }
    let(:request_return) { instance_double(JsonApiClient::ResultSet, has_errors?: false) }
    let(:request_headers) { resource.custom_headers }

    context 'success' do
      before { allow(requestor).to receive(:make_request).and_return request_return }

      it 'makes request only once if there is no error' do
        expect(requestor.send(:request, type, path, params)).to eq request_return
        expect(requestor).to have_received(:make_request).with(type, path, params, request_headers)
      end
    end

    context 'raising errors' do
      before do
        make_request_call_count = 0
        allow(requestor).to receive(:make_request) do
          if make_request_call_count == 1
            request_return
          else
            make_request_call_count += 1
            raise error
          end
        end
      end

      context 'JsonApiClient::Errors::ServerError' do
        let(:error) { JsonApiClient::Errors::ServerError.new('foo') }

        it 'makes request twice, is still successful' do
          expect(requestor.send(:request, type, path, params)).to eq request_return
          expect(requestor).to have_received(:make_request).with(type, path, params, request_headers).twice
        end
      end

      context 'JsonApiClient::Errors::ConnectionError' do
        let(:error) { JsonApiClient::Errors::ConnectionError.new('foo') }

        it 'makes request twice, is still successful' do
          expect(requestor.send(:request, type, path, params)).to eq request_return
          expect(requestor).to have_received(:make_request).with(type, path, params, request_headers).twice
        end
      end

      context 'JsonApiClient::Errors::NotFound' do
        let(:error) { JsonApiClient::Errors::NotFound.new('foo') }

        it 'makes request only once, and does not rescue error' do
          expect { requestor.send(:request, type, path, params) }.to raise_error error
          expect(requestor).to have_received(:make_request).with(type, path, params, request_headers).once
        end
      end

      context 'JsonApiClient::Errors::Conflict' do
        let(:error) { JsonApiClient::Errors::Conflict.new('foo') }

        it 'makes request only once, and does not rescue error' do
          expect { requestor.send(:request, type, path, params) }.to raise_error error
          expect(requestor).to have_received(:make_request).with(type, path, params, request_headers).once
        end
      end

      context 'other error raised' do
        let(:error) { StandardError.new('foo') }

        it 'calls request only once, and does not rescue error' do
          expect { requestor.send(:request, type, path, params) }.to raise_error error
          expect(requestor).to have_received(:make_request).with(type, path, params, request_headers).once
        end
      end
    end
  end

  describe '-handle_errors' do
    let(:has_errors) { false }

    context 'with a ResultSet' do
      let(:result) { instance_double(JsonApiClient::ResultSet) }

      before { allow(result).to receive(:has_errors?).and_return has_errors }

      context 'no errors' do
        it 'returns result' do
          expect(requestor.send(:handle_errors, result)).to be(result)
        end
      end

      context 'has errors' do
        let(:has_errors) { true }
        let(:errors) { instance_double(JsonApiClient::ErrorCollector) }
        let(:error) { instance_double(JsonApiClient::ErrorCollector::Error) }

        before do
          allow(result).to receive(:errors).and_return errors
          allow(errors).to receive(:first).and_return error
          allow(error).to receive(:[]).with(:status).and_return status
        end

        context 'error has a known status' do
          let(:status) { '400' }

          it 'raises correct error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::BadRequest
          end
        end

        context 'error has a unanticipated status' do
          let(:status) { '483' }

          it 'raises FrederickAPI::V2::Errors::Error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::Error
          end
        end

        context 'error has no status' do
          let(:status) { nil }

          it 'raises FrederickAPI::V2::Errors::Error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::Error
          end
        end
      end
    end

    context 'with a Resource' do
      let(:result) { instance_double(FrederickAPI::V2::Resource) }

      before { expect(result).to receive(:has_errors?).and_return has_errors }

      context 'no errors' do
        it 'returns result' do
          expect(requestor.send(:handle_errors, result)).to be(result)
        end
      end

      context 'has errors' do
        let(:has_errors) { true }
        let(:errors) { instance_double(JsonApiClient::ErrorCollector) }
        let(:error) { instance_double(JsonApiClient::ErrorCollector::Error) }

        before do
          allow(result).to receive(:errors).and_return errors
          allow(errors).to receive(:first).and_return error
          allow(error).to receive(:[]).with(:status).and_return status
        end

        context 'error has a known status' do
          let(:status) { '400' }

          it 'raises correct error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::BadRequest
          end
        end

        context 'error has a unanticipated status' do
          let(:status) { '483' }

          it 'raises FrederickAPI::V2::Errors::Error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::Error
          end
        end

        context 'error has no status' do
          let(:status) { nil }

          it 'raises FrederickAPI::V2::Errors::Error' do
            expect { requestor.send(:handle_errors, result) }.to raise_error FrederickAPI::V2::Errors::Error
          end
        end
      end
    end
  end

  describe '-make_request' do
    let(:response) { 'resp' }
    let(:expected_result) { 'expected' }
    let(:type) { 'type' }
    let(:path) { 'path' }
    let(:params) { 'params' }
    let(:headers) { 'headers' }

    before do
      allow(resource.parser).to receive(:parse).with(resource, response).and_return expected_result
      allow(requestor.connection).to receive(:run).and_return response
    end

    it 'returns expected' do
      expect(requestor.send(:make_request, type, path, params, headers)).to be expected_result
      expect(requestor.connection).to have_received(:run).with(type, path, params, headers)
    end
  end
end
