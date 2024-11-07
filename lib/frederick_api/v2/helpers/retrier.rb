# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Module to add retry logix
      module Retrier
        def retry_block(n)
          attempts = 1
          begin
            nr_log_attempts(attempts)
            yield
          rescue
            attempts += 1
            attempts <= n ? retry : raise
            sleep(attempts * 5)
          end
        end

        def nr_log_attempts(attempts)
          NewRelic::Agent.record_metric('FrolodexPageFetchAttempt', attempts)
        rescue
          nil
        end
      end
    end
  end
end
