# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::Helpers::Requestor do
  let(:superklass) { JsonApiClient::Query::Requestor }
  let(:requestor) { described_class.new(String) }

  it 'has right superclass' do
    expect(described_class.superclass).to eq superklass
  end

  describe '#request' do
    let(:error) {}
    let(:type) { 'type' }
    let(:path) { 'path' }
    let(:param) { 'param' }
    let(:request_args) { [type, path, param] }
    let(:super_instance) { superklass.new(String) }
    let(:super_request_call_args) { [] }
    let(:request_return) { 'request_return' }

    before do
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
