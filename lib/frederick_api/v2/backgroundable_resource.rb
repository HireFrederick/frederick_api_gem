# frozen_string_literal: true

module FrederickAPI
  module V2
    # This allows us to detect and parse incoming background job resources properly
    class BackgroundableResource < ::FrederickAPI::V2::Resource
      self.parser = ::FrederickAPI::V2::Helpers::BackgroundableParser
    end
  end
end
