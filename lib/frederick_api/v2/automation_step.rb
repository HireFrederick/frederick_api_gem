# frozen_string_literal: true

module FrederickAPI
  module V2
    # Resource for automation step
    class AutomationStep < Resource
      belongs_to :location
      belongs_to :automation

      self.read_only_attributes += %i[location_id automation_id]
    end
  end
end
