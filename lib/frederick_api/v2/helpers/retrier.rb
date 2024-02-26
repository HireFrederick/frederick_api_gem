module FrederickAPI
    module V2
      module Helpers
        module Retrier
            def retry_block(n)
                attempts = 0
                begin
                  yield
                rescue => e
                  attempts += 1
                  attempts < n ? retry : raise
                end
            end
        end
      end
    end
end

