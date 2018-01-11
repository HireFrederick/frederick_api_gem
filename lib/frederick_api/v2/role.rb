# frozen_string_literal: true

module FrederickAPI
  module V2
    # /v2/users
    class Role < Resource
      has_many :users
    end
  end
end
