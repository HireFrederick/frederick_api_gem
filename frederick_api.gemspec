# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frederick_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'frederick_api'
  spec.version       = FrederickAPI::VERSION
  spec.authors       = ['Frederick Engineering']
  spec.email         = ['tech@hirefrederick.com']

  spec.summary       = 'Frederick API Client'
  spec.description   = 'Ruby client for the Frederick API'
  spec.homepage      = 'https://github.com/BookerSoftwareInc/frederick_api_gem'
  spec.files         = Dir['{lib}/**/*', 'README.md']
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'json_api_client', '>= 1.5.1'
end
