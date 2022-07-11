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

          (total_pages - current_page).times do
            first_resource.class.with_headers(first_resource.custom_headers) do
              current_result_set = next_result_set(current_result_set)
              raise 'next link not found' unless current_result_set
              results.push(*current_result_set.to_a)
            end
          end
          results
        end

        # refetching the next link if no response is found due to elastic cache unknown beheviour.
        # bug link: https://dev.azure.com/mindbody/Marketing%20Products/_workitems/edit/1101861
        def next_result_set(current_result_set)
          if current_result_set
            response = current_result_set.pages.next
            response.present? ? response : current_result_set.pages.next
          else
            self.result_set.pages.next
          end
        end

        def total_pages
          if links['last']
            uri = result_set.links.link_url_for('last')
            last_params = params_for_uri(uri)
            last_params.fetch("page.#{page_param}") do
              current_page
            end.to_i
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
      end
    end
  end
end
