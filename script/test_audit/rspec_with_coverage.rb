# frozen_string_literal: true

# Runs RSpec with SimpleCov measuring, for repos whose spec_helper does not start SimpleCov.
#
# Usage: bundle exec ruby script/test_audit/rspec_with_coverage.rb <rspec args>
#
# SimpleCov must start before the application is loaded by spec_helper, so we start it
# here and then hand ARGV to RSpec's own executable. No test file is changed.
require "simplecov" # also loads .simplecov from the repo root
SimpleCov.start
load Gem.bin_path("rspec-core", "rspec")
