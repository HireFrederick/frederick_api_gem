# frozen_string_literal: true

module FrederickAPI
  module V2
    # V2 Frederick API async background job class for parsing
    # background job responses coming from API.
    class BackgroundJob < Resource
      attr_accessor :response

      def has_errors?
        @attributes['status'] == 'error'
      end

      def retry_after
        try_time = @response[:headers]['retry-after'].to_i
        @retry_after ||= try_time > 1 ? try_time : 1
      end

      def response_code
        @response_code ||= @response[:status]
      end

      def status
        @attributes['status']
      end

      # frolodex fills a failed job's `messages` with plain strings (the exception text).
      # Errors::Error#to_s reads ['detail'] from the first error, which is nil on a String and
      # produced the empty "Client Error: " message (AB#1284255). Wrap strings as JSON:API-style
      # error hashes so the real reason survives; keep the copied text bounded because it can be
      # long (for example a SQL statement).
      def errors
        messages = @attributes['messages']
        messages = [messages].compact unless messages.is_a?(Array)
        messages.map { |message| message.is_a?(Hash) ? message : { 'detail' => message.to_s[0, 1000] } }
      end

      def id
        @attributes['id']
      end
    end
  end
end
