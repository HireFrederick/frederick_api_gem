# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Requestor for v2 client to use built on top of JsonApiClient::Query::Requestor
      class Requestor < JsonApiClient::Query::Requestor
        attr_reader :path

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

        # Retry once on unhandled server errors
        def request(type, path, params)
          handle_errors(super)
        rescue JsonApiClient::Errors::ConnectionError, JsonApiClient::Errors::ServerError => ex
          raise ex if ex.is_a?(JsonApiClient::Errors::NotFound) || ex.is_a?(JsonApiClient::Errors::Conflict)
          handle_errors(super)
        end

        private

          def handle_errors(result)
            return result unless result.has_errors?
            error_klass = FrederickAPI::V2::Errors::ERROR_CODES[result.errors.first[:status]] ||
              FrederickAPI::V2::Errors::Error
            raise error_klass, result
          end
      end
    end
  end
end
