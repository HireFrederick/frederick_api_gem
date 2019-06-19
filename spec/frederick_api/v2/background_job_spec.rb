# frozen_string_literal: true

require 'spec_helper'

describe FrederickAPI::V2::BackgroundJob do
  it_behaves_like 'v2_resource'

  describe 'class attributes' do
    describe 'read_only_attributes' do
      let(:base_read_only_attributes) { %i[id type links meta relationships] }

      it 'has right read only attributes' do
        expect(described_class.read_only_attributes).to eq base_read_only_attributes
        expect(described_class.superclass.read_only_attributes).to eq base_read_only_attributes
      end
    end
  end
end
