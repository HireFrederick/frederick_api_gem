# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/locations/:location_id/interactions
    class Interaction < Resource
      belongs_to :location
    end
  end
end
