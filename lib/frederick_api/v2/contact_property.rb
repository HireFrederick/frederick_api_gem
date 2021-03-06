# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/contact_properties
    class ContactProperty < Resource
      belongs_to :location
      has_one :contact_type

      self.read_only_attributes += [:location_id]
    end
  end
end
