# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Module to add retry logic
      module Retrier
        def retry_block(max_attempts)
          attempts = 1
          begin
            nr_log_attempts(attempts)
            yield
          rescue StandardError
            attempts += 1
            raise unless attempts <= max_attempts

            sleep((attempts - 1) * 5)
            retry
          end
        end

        def nr_log_attempts(attempts)
          NewRelic::Agent.record_metric('FrolodexPageFetchAttempt', attempts)
        rescue StandardError
          nil
        end
      end
    end
  end
end
