# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/contact_types
    class ContactType < Resource
      belongs_to :location
      self.read_only_attributes += [:location_id]
    end
  end
end
