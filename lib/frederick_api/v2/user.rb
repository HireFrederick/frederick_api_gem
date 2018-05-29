# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/users
    class User < Resource
      has_many :roles, class_name: 'FrederickAPI::V2::Role'
      has_many :permitted_locations, class_name: 'FrederickAPI::V2::Location'
    end
  end
end
