# frozen_string_literal: true

module FrederickApi
  module V2
    module Models
      # Class from which Frederick V2 Models inherit
      # Inherits functionality from JsonApiClient::Resource
      class BaseResource < JsonApiClient::Resource
        self.query_builder = FrederickApi::Utils::JsonApiQueryBuilder

        def self.site
          "#{FrederickApi.config.base_url}/v2/"
        end

        def self.with_access_token(token)
          with_headers(authorization: "Bearer #{token}") do
            yield
          end
        end

        def self.custom_headers
          super.merge(x_api_key: FrederickApi.config.api_key)
        end
      end
    end
  end
end
