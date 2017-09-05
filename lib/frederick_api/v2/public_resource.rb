# frozen_string_literal: true

module FrederickAPI
  module V2
    # Class from which Frederick V2 PUBLIC Resources inherit
    class PublicResource < Resource
      def self.site
        "#{top_level_namespace.config.public_base_url}/v2/"
      end
    end
  end
end
