# frozen_string_literal: true

module FrederickAPI
  module V2
    module Helpers
      # HasMany association that supports returning a query builder instead of a simple array
      # Allows querying of the association such as `contact_list.contacts.select('properties.external_id').all`
      module HasMany
        extend ActiveSupport::Concern

        # Class methods added to resource
        module ClassMethods
          def has_many(attr_name, options = {})
            self.associations = self.associations + [HasMany::Association.new(attr_name, self, options)]
          end
        end

        # Class used to request data for has_many association
        class Association < JsonApiClient::Associations::BaseAssociation
          def query_builder(url)
            association_class.query_builder.new(
              association_class,
              association_class.requestor_class.new(association_class, url)
            )
          end

          def data(url)
            query_builder(url)
          end
        end
      end
    end
  end
end
