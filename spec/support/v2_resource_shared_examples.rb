# frozen_string_literal: true

RSpec.shared_examples 'v2_resource' do
  describe 'superclass' do
    it 'inherits from Resource' do
      expect(described_class < FrederickAPI::V2::Resource).to be_truthy
    end
  end
end

RSpec.shared_examples 'belongs_to :location' do
  it 'belongs_to :location' do
    expect(described_class.path).to include('location_id')
  end
end
