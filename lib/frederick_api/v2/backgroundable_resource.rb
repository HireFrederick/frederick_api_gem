module FrederickAPI
  module V2
    class BackgroundableResource < ::FrederickAPI::V2::Resource
      self.parser = ::FrederickAPI::V2::Helpers::BackgroundableParser
    end
  end
end