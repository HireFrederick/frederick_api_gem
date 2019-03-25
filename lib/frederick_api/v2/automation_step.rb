# frozen_string_literal: true

module FrederickAPI
  module V2
    class AutomationStep < Resource
      belongs_to :location
      belongs_to :automation

      self.read_only_attributes += [:location_id, :automation_id]
    end
  end
end
