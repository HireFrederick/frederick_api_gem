# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Requestor for v2 client to use built on top of JsonApiClient::Query::Requestor
      class Requestor < JsonApiClient::Query::Requestor
        # Retry once on unhandled server errors
        def request(type, path, params)
          super
        rescue JsonApiClient::Errors::ConnectionError, JsonApiClient::Errors::ServerError => ex
          raise ex if ex.is_a?(JsonApiClient::Errors::NotFound) || ex.is_a?(JsonApiClient::Errors::Conflict)
          super
        end
      end
    end
  end
end
