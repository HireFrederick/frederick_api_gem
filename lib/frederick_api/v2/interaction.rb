# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/interactions
    class Interaction < Resource
      belongs_to :location
      has_one :contact

      self.read_only_attributes += [:location_id]
    end
  end
end
