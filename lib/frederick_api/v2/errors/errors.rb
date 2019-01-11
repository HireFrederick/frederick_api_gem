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
      class BackgroundJobFailure < Error
        def initialize(job)
          @job = job
          super(job)
        end
      end

      ERROR_CODES = {
        '400' => BadRequest,
        '422' => UnprocessableEntity
      }.freeze
    end
  end
end
