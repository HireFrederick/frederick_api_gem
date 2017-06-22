# frozen_string_literal: true

module FrederickAPI
  module V2
    class ContactProperty < Resource
      belongs_to :location
    end
  end
end
