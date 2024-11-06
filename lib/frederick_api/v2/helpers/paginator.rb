# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # Custom paginator for json api client
      # Fixes param names for pagination
      # Also adds ability to get all records from a paginated API
      class Paginator < JsonApiClient::Paginating::Paginator
        include FrederickAPI::V2::Helpers::Retrier
        self.page_param = 'number'
        self.per_page_param = 'size'

        # rubocop:disable Metrics/AbcSize
        def all_records
          current_result_set = nil
          results = self.result_set.to_a
          first_resource = self.result_set.first
          page_fetch_count = pages_to_be_fetched
          nr_log_page_count(page_fetch_count)

          page_fetch_count.times do
            first_resource.class.with_headers(first_resource.custom_headers) do
              retry_block(FrederickAPI.config.retry_times, location_id) do
                current_result_set = current_result_set ? current_result_set.pages.next : self.result_set.pages.next
                raise 'next link not found' unless current_result_set
              end
              results.push(*current_result_set.to_a)
            end
          end
          results
        end
        # rubocop:enable Metrics/AbcSize

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

        def is_campaign_source?
          uri = result_set.links.link_url_for('first')
          first_params = params_for_uri(uri)
          filter_string = first_params.fetch('filter.filters')
          filters_array = JSON.parse(filter_string).flatten
          filters_array.each do |filter_hash|
            if filter_hash['operator'] == 'has_no_interaction' &&
                filter_hash['interaction_type'] == 'delivered_email' &&
                filter_hash['source_type'] == 'Campaign'
              return true
            end
          end

          false
        end

        def eligible_page_count
          return (total_pages - current_page) unless FrederickAPI.config.emails_per_day_limit_enabled

          cache_key = "emails_sent_today_#{location_id}"
          emails_sent_today = Rails.cache.read(cache_key) || 0
          emails_per_day_limit = FrederickAPI.config.emails_per_day_limit
          batch_size = FrederickAPI.config.frolodex_batch_fetch_size || 1000
          (emails_per_day_limit - emails_sent_today) / batch_size
        rescue => e
          NewRelic::Agent.notice_error(e, first_link: first_link)
        end

        def pages_to_be_fetched
          if FrederickAPI.config.jsonapi_campaign_check_enabled && is_campaign_source?
            [total_pages - current_page, eligible_page_count + 1].min
          else
            total_pages - current_page
          end
        end

        # log pages fetched for further analysis.
        def nr_log_page_count(page_count)
          NewRelic::Agent.record_metric('FrolodexPageFetchCount', page_count)
        rescue
          nil
        end

        def first_link
          links['first']
        end

        def location_id
          puts first_link
          first_link.match(%r{locations/([a-f0-9\-]+)/contacts})[1]
        end
      end
    end
  end
end
