# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      module Retrier
        def retry_block(n)
          attempts = 1
          begin
            yield
          rescue
            attempts += 1
            attempts <= n ? retry : raise
            sleep (attempts * 5)
          end
        end
      end
    end
  end
end
