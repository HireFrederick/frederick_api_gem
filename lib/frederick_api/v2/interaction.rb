# frozen_string_literal: true

module FrederickAPI
  module V2
    class Interaction < Resource
      belongs_to :location
    end
  end
end
