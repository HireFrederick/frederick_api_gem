# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Module to add retry logix
      module Retrier
        def retry_block(n, location_id = nil)
          attempts = 1
          begin
            yield
          rescue
            attempts += 1
            Rails.logger.warn("Frolodex contacts retry - attempt: #{attempts}, location_id: #{location_id}")
            nr_log_attempts(attempts)
            attempts <= n ? retry : raise
            sleep(attempts * 5)
          end
        end

        def nr_log_attempts(attempts)
          NewRelic::Agent.record_metric('FrolodexPageFetchAttempts', attempts)
        rescue
          nil
        end
      end
    end
  end
end
