# frozen_string_literal: true

# Merges SimpleCov shard results into one report for a layer.
#
# Usage: bundle exec ruby script/test_audit/collate.rb <group> <glob of .resultset.json files>
#   e.g. bundle exec ruby script/test_audit/collate.rb unit 'resultsets/resultset-unit-*/.resultset.json'
#
# Writes coverage-merged/<group>/index.html, coverage.json and summary.json.
require "simplecov"
require "simplecov_json_formatter"
require "json"

group, glob = ARGV
abort("usage: collate.rb <group> <glob>") unless group && glob
files = Dir[glob].sort
abort("no resultset files matched #{glob}") if files.empty?

SimpleCov.coverage_dir "coverage-merged/#{group}"
SimpleCov.collate(files, nil, ignore_timeout: true) do
  formatter SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter]
  )
end

result = SimpleCov.result
stats = result.coverage_statistics
summary = {
  group: group,
  resultsets: files,
  files_measured: result.files.size,
  line: {
    covered: stats[:line].covered,
    total: stats[:line].total,
    percent: stats[:line].percent.round(2)
  }
}
if stats[:branch]
  summary[:branch] = {
    covered: stats[:branch].covered,
    total: stats[:branch].total,
    percent: stats[:branch].percent.round(2)
  }
end
File.write("coverage-merged/#{group}/summary.json", JSON.pretty_generate(summary))
puts JSON.generate(summary)
