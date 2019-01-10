module FrederickAPI
  module V2
    module Helpers
      class BackgroundableParser < ::JsonApiClient::Parsers::Parser
        def self.parse(klass, response)
          result_set = super(klass, response)
          return result_set unless result_set&.first&.type == "background_jobs"
          result_set = super(::FrederickAPI::V2::BackgroundJob, response)
          result_set&.first&.meta = { headers: response.headers, status: response.status }
          result_set
        end
      end
    end
  end
end