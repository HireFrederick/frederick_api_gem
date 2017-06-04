# frozen_string_literal: true

require 'spec_helper'

module FrederickApi::V2::Models
  RSpec.describe Location do
    describe 'superclass' do
      it 'inherits from BaseResource' do
        expect(described_class.superclass).to eq BaseResource
      end
    end
  end
end
