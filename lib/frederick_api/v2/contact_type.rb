# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/contact_types
    class ContactType < Resource
      belongs_to :location
      has_many :contact_properties
      has_many :contacts

      self.read_only_attributes += [:location_id]
    end
  end
end
