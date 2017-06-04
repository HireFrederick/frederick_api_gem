# frozen_string_literal: true

module FrederickApi # :nodoc:
  class << self
    attr_writer :config
  end

  # You may use `FrederickApi.configure` to configure the Frederick
  # Internal API Gem or you can use environment variables. By default, the
  # client will connect to staging with a blank API key.
  # @see .configure
  class Configuration
    DEFAULTS = {
      base_url: ENV['FREDERICK_API_BASE_URL'] ||
        'https://api.staging.hirefrederick.com',
      api_key: ENV['FREDERICK_API_KEY']
    }.freeze

    attr_accessor :base_url, :api_key

    def initialize
      @base_url = DEFAULTS[:base_url]
      @api_key = DEFAULTS[:api_key]
    end
  end

  # Configure FrederickApi, for example in an initializer or (better
  # yet) in one of the `config/environments/*.rb` files so you can have it
  # configured differently per environment. For example, you may want to use
  # staging API in staging environment, or may want different timeouts in
  # development environment than production.
  #
  # @example
  #   # config/environments/staging.rb
  #   ...
  #   FrederickApi.configure do |c|
  #     c.base_url = 'https://api.staging.hirefrederick.com/v1'
  #     c.api_key = '1234-5678-1234-5678-1234-5678'
  #   end
  #   ...
  #
  # @yield [configuration] block to configure FrederickApi
  # @return [FrederickApi::Configuration] the completed configuration
  def self.configure
    yield(config)
  end

  # Returns a reference to the current configuration.
  #
  # @return [FrederickApi::Configuration]
  def self.config
    @config ||= Configuration.new
  end
end
