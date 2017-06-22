# frozen_string_literal: true

module FrederickAPI
  module V2
    class Contact < Resource
      belongs_to :location
    end
  end
end
