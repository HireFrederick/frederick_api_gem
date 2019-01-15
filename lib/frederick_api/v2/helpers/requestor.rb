# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Requestor for v2 client to use built on top of JsonApiClient::Query::Requestor
      class Requestor < JsonApiClient::Query::Requestor
        attr_reader :path

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
          return request(:post, path, params, 'X-Request-Method' => 'GET') if get_via_post_path?(path)
          request(:get, path, params)
        end

        def linked(path)
          uri = URI.parse(path)
          return super unless get_via_post_path?(uri.path)

          path_without_params = "#{uri.scheme}://#{uri.host}#{uri.path}"
          params = uri.query ? CGI.parse(uri.query).each_with_object({}) { |(k, v), h| h[k] = v[0] } : {}
          request(:post, path_without_params, params, 'X-Request-Method' => 'GET')
        end

        # Retry once on unhandled server errors
        def request(type, path, params, additional_headers = {})
          headers = klass.custom_headers.merge(additional_headers)
          begin
            handle_background(handle_errors(make_request(type, path, params, headers)))
          rescue JsonApiClient::Errors::ConnectionError, JsonApiClient::Errors::ServerError => ex
            raise ex if ex.is_a?(JsonApiClient::Errors::NotFound) || ex.is_a?(JsonApiClient::Errors::Conflict)
            handle_errors(make_request(type, path, params, headers))
          end
        end

        private
          def handle_background(response)
            return response unless (job = response&.first).is_a? ::FrederickAPI::V2::BackgroundJob
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

          def make_request(type, path, params, headers)
            faraday_response = connection.run(type, path, params, headers)
            return klass.parser.parse(klass, faraday_response) unless faraday_response.status == 303
            linked(faraday_response.headers['location'])
          end

          def get_via_post_path?(path)
            GET_VIA_POST_PATHS.any? { |r| r.match(path) }
          end
      end
    end
  end
end
