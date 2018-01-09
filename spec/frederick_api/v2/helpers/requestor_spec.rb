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

  describe '#handle_errors' do
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

  describe '#request' do
    let(:error) {}
    let(:type) { 'type' }
    let(:path) { 'path' }
    let(:param) { 'param' }
    let(:request_args) { [type, path, param] }
    let(:super_instance) { superklass.new(String) }
    let(:super_request_call_args) { [] }
    let(:request_return) { instance_double(JsonApiClient::ResultSet) }

    before do
      allow(request_return).to receive(:has_errors?).and_return false
      allow_any_instance_of(superklass).to receive(:request) do |*args|
        super_request_call_args << args[1..-1]
        raise(error) if super_request_call_args.length == 1 && error
        request_return
      end
    end

    it 'calls request only once if there is no error' do
      expect(requestor.send(:request, *request_args)).to eq request_return
      expect(super_request_call_args).to eq [request_args]
    end

    context 'JsonApiClient::Errors::ServerError' do
      let(:error) { JsonApiClient::Errors::ServerError.new('foo') }

      it 'calls request twice' do
        expect(requestor.send(:request, *request_args)).to eq request_return
        expect(super_request_call_args).to eq [request_args, request_args]
      end
    end

    context 'JsonApiClient::Errors::ConnectionError' do
      let(:error) { JsonApiClient::Errors::ConnectionError.new('foo') }

      it 'calls request twice' do
        expect(requestor.send(:request, *request_args)).to eq request_return
        expect(super_request_call_args).to eq [request_args, request_args]
      end
    end

    context 'JsonApiClient::Errors::NotFound' do
      let(:error) { JsonApiClient::Errors::NotFound.new('foo') }

      it 'calls request only once, and does not rescue error' do
        expect { requestor.send(:request, *request_args) }.to raise_error error
        expect(super_request_call_args).to eq [request_args]
      end
    end

    context 'JsonApiClient::Errors::Conflict' do
      let(:error) { JsonApiClient::Errors::Conflict.new('foo') }

      it 'calls request only once, and does not rescue error' do
        expect { requestor.send(:request, *request_args) }.to raise_error error
        expect(super_request_call_args).to eq [request_args]
      end
    end

    context 'other error raised' do
      let(:error) { StandardError.new('foo') }

      it 'calls request only once, and does not rescue error' do
        expect { requestor.send(:request, *request_args) }.to raise_error error
        expect(super_request_call_args).to eq [request_args]
      end
    end
  end
end
