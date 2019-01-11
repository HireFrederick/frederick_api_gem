# frozen_string_literal: true

module FrederickAPI
  module V2
    # V2 Frederick API async background job record, does not use a DB, just
    # exists to provide a place to parse background job responses coming from
    # API so that we can handle them properly.
    class BackgroundJob < Resource
      attr_accessor :meta
      belongs_to :contact

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

      def messages
        @attributes['messages']
      end

      def id
        @attributes['id']
      end
    end
  end
end
