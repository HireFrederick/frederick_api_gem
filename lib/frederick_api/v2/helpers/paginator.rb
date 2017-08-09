# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Custom paginator for json api client
      # Fixes param names for pagination
      # Also adds ability to get all records from a paginated API
      class Paginator < JsonApiClient::Paginating::Paginator
        self.page_param = 'page.number'
        self.per_page_param = 'page.size'

        def all_records
          current_result_set = nil
          results = self.result_set.to_a
          first_resource = self.result_set.first

          (total_pages - current_page).times do
            first_resource.class.with_headers(first_resource.custom_headers) do
              current_result_set = current_result_set ? current_result_set.pages.next : self.result_set.pages.next
              raise 'next link not found' unless current_result_set
              results.push(*current_result_set.to_a)
            end
          end

          results
        end
      end
    end
  end
end
