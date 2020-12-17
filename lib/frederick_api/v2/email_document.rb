# frozen_string_literal: true

module FrederickAPI
  module V2
    # V2 Email Document Resource
    class EmailDocument < Resource
      belongs_to :location

      self.read_only_attributes += [:location_id]
    end
  end
end
