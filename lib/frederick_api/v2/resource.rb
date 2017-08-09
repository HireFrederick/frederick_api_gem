# frozen_string_literal: true

module FrederickAPI
  module V2
    # Class from which Frederick V2 Resources inherit
    # Inherits functionality from JsonApiClient::Resource
    class Resource < JsonApiClient::Resource
      self.query_builder = FrederickAPI::V2::Helpers::QueryBuilder
      self.paginator = FrederickAPI::V2::Helpers::Paginator
      self.requestor_class = FrederickAPI::V2::Helpers::Requestor

      attr_accessor :custom_headers

      def initialize(params = {})
        self.custom_headers = self.class.custom_headers
        super
      end

      def self.site
        "#{FrederickAPI.config.base_url}/v2/"
      end

      def self.with_access_token(token)
        with_headers(authorization: "Bearer #{token}") do
          yield
        end
      end

      def self.custom_headers
        super.merge(x_api_key: FrederickAPI.config.api_key)
      end
    end
  end
end
