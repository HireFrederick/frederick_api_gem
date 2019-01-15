# frozen_string_literal: true

module FrederickAPI
  module V2
    # V2 Frederick API async background job class for parsing
    # background job responses coming from API.
    class BackgroundJob < Resource
      attr_accessor :meta
      belongs_to :contact

      def has_errors?
        @attributes['status'] == 'error'
      end

      def retry_after
        try_time = @meta[:headers]['retry-after'].to_i
        @retry_after ||= try_time > 1 ? try_time : 1
      end

      def response_code
        @response_code ||= @meta[:status]
      end

      def status
        @attributes['status']
      end

      def errors
        @attributes['errors']
      end

      def id
        @attributes['id']
      end
    end
  end
end
