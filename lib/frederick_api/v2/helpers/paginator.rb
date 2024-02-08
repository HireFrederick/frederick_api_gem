# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Custom paginator for json api client
      # Fixes param names for pagination
      # Also adds ability to get all records from a paginated API
      class Paginator < JsonApiClient::Paginating::Paginator
        self.page_param = 'number'
        self.per_page_param = 'size'

        def all_records
          current_result_set = nil
          results = self.result_set.to_a
          first_resource = self.result_set.first

          remaining_pages = total_pages - current_page

          remaining_pages.times do |page|
            first_resource.class.with_headers(first_resource.custom_headers) do
              current_result_set = next_result_set(current_result_set)
              break if (page + 1 >= remaining_pages) && current_result_set.nil?
              raise 'next link not found' if current_result_set.nil?
              results.push(*current_result_set.to_a)
            end
          end

          results
        end

        def total_pages
          if links['last']
            uri = result_set.links.link_url_for('last')
            last_params = params_for_uri(uri)
            last_params.fetch("page.#{page_param}", current_page).to_i
          else
            current_page
          end
        end

        def per_page
          params.fetch("page.#{per_page_param}") do
            result_set.length
          end.to_i
        end

        def current_page
          params.fetch("page.#{page_param}", 1).to_i
        end

        private

          # refetching the next link if no response is found.
          def next_result_set(current_result_set)
            if current_result_set
              response = current_result_set.pages.next
            else
              response = self.result_set.pages.next
            end

            response.present? ? response : nil
          end
      end
    end
  end
end
