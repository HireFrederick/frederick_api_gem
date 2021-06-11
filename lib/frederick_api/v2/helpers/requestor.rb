# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Requestor for v2 client to use built on top of JsonApiClient::Query::Requestor
      class Requestor < JsonApiClient::Query::Requestor
        attr_reader :path

        # For backward compatibility, preserve these JSON API client errors instead of raising
        # FrederickAPI::Errors::Error
        JSON_API_CLIENT_PASSTHROUGH_ERRORS = [
          JsonApiClient::Errors::NotAuthorized,
          JsonApiClient::Errors::AccessDenied,
          JsonApiClient::Errors::NotFound,
          JsonApiClient::Errors::Conflict,
          JsonApiClient::Errors::ServerError,
          JsonApiClient::Errors::UnexpectedStatus
        ].freeze

        # Paths that may have an unbounded query param length so we should always use a POST
        # instead of a GET to get around AWS Cloudfront limitations
        GET_VIA_POST_PATHS = [
          %r{^.*locations\/[^\/]+\/contacts$},
          %r{^.*locations\/[^\/]+\/interactions$}
        ].map(&:freeze).freeze

        def initialize(klass, path = nil)
          @klass = klass
          @path = path
        end

        def resource_path(parameters)
          base_path = path || klass.path(parameters)
          if (resource_id = parameters[klass.primary_key])
            File.join(base_path, encode_part(resource_id))
          else
            base_path
          end
        end

        def get(params = {})
          path = resource_path(params)

          params.delete(klass.primary_key)
          if get_via_post_path?(path)
            return request(:post, path, body: params.to_json, additional_headers: { 'X-Request-Method' => 'GET' })
          end

          request(:get, path, params: params)
        end

        def linked(path)
          uri = URI.parse(path)
          return super unless get_via_post_path?(uri.path)

          path_without_params = "#{uri.scheme}://#{uri.host}#{uri.path}"
          params = uri.query ? CGI.parse(uri.query).each_with_object({}) { |(k, v), h| h[k] = v[0] } : {}
          request(:post, path_without_params, body: params.to_json, additional_headers: { 'X-Request-Method' => 'GET' })
        end

        # Retry once on unhandled server errors
        def request(type, path, params: nil, body: nil, additional_headers: {})
          headers = klass.custom_headers.merge(additional_headers)
          make_request = proc do
            handle_background(handle_errors(make_request(type, path, params: params, body: body, headers: headers)))
          end

          begin
            make_request.call
          rescue JsonApiClient::Errors::ConnectionError, JsonApiClient::Errors::ServerError => ex
            raise ex if ex.is_a?(JsonApiClient::Errors::NotFound) || ex.is_a?(JsonApiClient::Errors::Conflict)
            make_request.call
          end
        end

        private
          def handle_background(response)
            return response unless
                (job = response&.first).is_a?(::FrederickAPI::V2::BackgroundJob) && job.status != 'complete'
            raise FrederickAPI::V2::Errors::BackgroundJobFailure, job if job.has_errors?
            sleep job.retry_after
            linked(job.links.attributes['self'])
          end

          def handle_errors(result)
            return result unless result.has_errors?
            error_klass = FrederickAPI::V2::Errors::ERROR_CODES[result.errors.first[:status]] ||
              FrederickAPI::V2::Errors::Error
            raise error_klass, result
          end

          def make_request(type, path, params:, body:, headers:)
            faraday_response = connection.run(type, path, params: params, body: body, headers: headers)
            return klass.parser.parse(klass, faraday_response) unless faraday_response.status == 303

            linked(faraday_response.headers['location'])
          rescue JsonApiClient::Errors::ClientError => e
            handle_json_api_client_error(e)
          end

          def get_via_post_path?(path)
            GET_VIA_POST_PATHS.any? { |r| r.match(path) }
          end

          def handle_json_api_client_error(error)
            raise error if JSON_API_CLIENT_PASSTHROUGH_ERRORS.include?(error.class)

            klass.parser.parse(klass, error.env.response)
          end
      end
    end
  end
end
