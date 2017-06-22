# frozen_string_literal: true

require 'spec_helper'

module FrederickAPI::V2
  RSpec.describe ContactType do
    it_behaves_like 'v2_resource'
    it_behaves_like 'belongs_to :location'
  end
end
