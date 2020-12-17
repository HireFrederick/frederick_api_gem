# frozen_string_literal: true

require 'active_support/core_ext/module'

module FrederickAPI
  module V2
    module Helpers
      # Used to convert nested params to dot notation for Frederick API
      class QueryBuilder < JsonApiClient::Query::Builder
        attr_reader :requestor

        def initialize(klass, opts = {})
          super(klass, opts)
          @requestor = opts[:requestor] || klass.requestor
        end

        def params
          to_dot_params(
            filter_params.merge(pagination_params.merge(includes_params).merge(select_params))
          ).merge(order_params)
            .merge(primary_key_params)
            .merge(path_params)
            .merge(additional_params)
        end

        def filter_params
          super_filter_params = super

          if (filters = super_filter_params[:filter])
            filters.each do |filter_name, filter_val|
              filters[filter_name] = filter_val.join(',') if filter_val.is_a?(Array)
            end
          end

          super_filter_params
        end

        def all_records
          self.all.pages.all_records
        end

        def to_dot_params(object, prefix = nil)
          return {} if object == {}

          if object.is_a? Hash
            object.map do |key, value|
              if prefix
                to_dot_params value, "#{prefix}.#{key}"
              else
                to_dot_params value, key.to_s
              end
            end.reduce(&:merge)
          else
            { prefix => object }
          end
        end

        protected

          def _fetch
            (requestor || klass.requestor).get(params)
          end

        private

          def _new_scope(opts = {})
            self.class.new(@klass,
                           requestor:         requestor,
                           primary_key:       opts.fetch(:primary_key, @primary_key),
                           pagination_params: @pagination_params.merge(opts.fetch(:pagination_params, {})),
                           path_params:       @path_params.merge(opts.fetch(:path_params, {})),
                           additional_params: @additional_params.merge(opts.fetch(:additional_params, {})),
                           filters:           @filters.merge(opts.fetch(:filters, {})),
                           includes:          @includes + opts.fetch(:includes, []),
                           orders:            @orders + opts.fetch(:orders, []),
                           fields:            @fields + opts.fetch(:fields, []))
          end
      end
    end
  end
end
