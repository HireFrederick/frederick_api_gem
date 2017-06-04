# frozen_string_literal: true

require 'spec_helper'

module FrederickAPI::V2
  RSpec.describe User do
    describe 'superclass' do
      it_behaves_like 'v2_resource'
    end
  end
end
