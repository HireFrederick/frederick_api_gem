# frozen_string_literal: true

module FrederickAPI
  module V2
    # Resource for automation step
    class AutomationStep < Resource
      belongs_to :location
      has_one :automation
      has_one :previous_automation_step, class_name: 'FrederickAPI::V2::AutomationStep'

      self.read_only_attributes += %i[location_id]
    end
  end
end
