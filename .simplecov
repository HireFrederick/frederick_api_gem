# frozen_string_literal: true

# Coverage configuration for the Marketing Suite test audit.
#
# SimpleCov loads this file automatically when `require "simplecov"` runs.
# It only configures; the caller starts measurement.
#
# command_name  labels each result (unit-0, integration-0, cucumber-0, ...) so
#               script/test_audit/collate.rb can merge per layer.
# track_files   counts every .rb and .rake file under app/ and lib/, so a file
#               with no tests contributes 0% instead of being ignored.
# add_filter    keeps non-application code out of the denominator.
# branch        records branch coverage next to line coverage.
# merge_timeout shard results are hours old by the time they are merged;
#               never discard them for being stale.
SimpleCov.configure do
  command_name ENV.fetch("SIMPLECOV_COMMAND_NAME", "rspec")
  track_files "{app,lib}/**/*.{rb,rake}"
  add_filter %w[/spec/ /features/ /config/ /db/ /vendor/ /bin/ /script/ /tmp/ /log/ /public/ /node_modules/ /client/]
  enable_coverage :branch
  merge_timeout 86_400
end
