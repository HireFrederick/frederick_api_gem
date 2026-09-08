# frozen_string_literal: true

module FrederickAPI
  module V2
    module Errors
      # Base exception class for client errors (i.e. validation, bad request)
      class Error < JsonApiClient::Errors::ClientError
        attr_reader :errors

        # Initialize with a JsonApiClient::ResultSet or a Resource
        def initialize(result)
          # @env is used in base class JsonApiClient::Errors::Error
          @env = result
          @errors = result.errors || []
        end

        def to_s
          return "Client Error: #{self.errors.first['detail']}" if self.errors.any?
          super
        end
      end

      class BadRequest < Error; end
      class UnprocessableEntity < Error; end

      # an exception class for when the server reports that a
      # long running job has failed.
      class BackgroundJobFailure < Error; end

      # Raised when the API, or the gateway in front of it, answers HTTP 429 Too Many Requests.
      # Not an Errors::Error: a 429 carries no JSON:API error document, only the Faraday env.
      class RateLimited < JsonApiClient::Errors::ClientError
        def initialize(env, msg = nil)
          super(env, msg || "429 Too Many Requests: #{env[:url]}")
        end

        # Seconds the server asked us to wait (Retry-After header, delay-seconds form), else nil
        def retry_after
          headers = env[:response_headers]
          value = headers && headers['Retry-After']
          value.to_s =~ /\A\d+\z/ ? value.to_i : nil
        end
      end

      ERROR_CODES = {
        '400' => BadRequest,
        '422' => UnprocessableEntity
      }.freeze
    end
  end
end
