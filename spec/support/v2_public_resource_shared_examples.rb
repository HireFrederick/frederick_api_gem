# frozen_string_literal: true

RSpec.shared_examples 'v2_public_resource' do
  describe 'superclass' do
    it 'inherits from Resource' do
      expect(described_class.superclass).to be FrederickAPI::V2::PublicResource
    end
  end
end
