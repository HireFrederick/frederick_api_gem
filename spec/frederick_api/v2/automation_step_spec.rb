# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::AutomationStep do
  it_behaves_like 'v2_resource'
  it_behaves_like 'belongs_to :location'

  describe 'class attributes' do
    describe 'read_only_attributes' do
      it 'has right read only attributes' do
        expect(described_class.read_only_attributes).to eq(
          %i[id type links meta relationships location_id automation_id]
        )
      end
    end
  end
end
