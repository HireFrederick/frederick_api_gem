# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/contacts
    class Contact < Resource
      belongs_to :location
      has_one :contact_type
      has_one :parent, class_name: 'FrederickAPI::V2::Contact'
      has_one :referred_by_contact, class_name: 'FrederickAPI::V2::Contact'
      has_many :children, class_name: 'FrederickAPI::V2::Contact'
      has_many :referred_contacts, class_name: 'FrederickAPI::V2::Contact'
      has_many :contact_lists
      has_many :interactions

      self.read_only_attributes += [:location_id]
    end
  end
end
