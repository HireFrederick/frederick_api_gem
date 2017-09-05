# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'byebug'
require 'webmock/rspec'
require 'frederick_api'
require 'support/v2_resource_shared_examples'
require 'support/v2_public_resource_shared_examples'

configuration_proc = proc do |c|
  c.base_url = 'http://test.host'
  c.public_base_url = 'http://public.test.host'
  c.api_key = '1234-5678-8765-4321'
end

FrederickAPI.configure(&configuration_proc)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.warnings = true
  config.profile_examples = 10
  config.order = :random
  config.default_formatter = 'doc' if config.files_to_run.one?
end
