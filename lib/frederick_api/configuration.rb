# frozen_string_literal: true

module FrederickAPI # :nodoc:
  class << self
    attr_writer :config
  end

  # You may use `FrederickAPI.configure` to configure the Frederick
  # Internal API Gem or you can use environment variables. By default, the
  # client will connect to staging with a blank API key.
  # @see .configure
  class Configuration
    DEFAULTS = {
      base_url: ENV['FREDERICK_API_BASE_URL'] ||
        'https://api.staging.hirefrederick.com',
      public_base_url: ENV['FREDERICK_API_PUBLIC_BASE_URL'] ||
        'https://api.public.staging.hirefrederick.com',
      api_key: ENV['FREDERICK_API_KEY'],
      retry_times: (ENV['FREDERICK_API_RETRY_TIMES'] || 1).to_i,
      jsonapi_campaign_check_enabled: (ENV['JSONAPI_CAMPAIGN_CHECK_ENABLED'] == 'true'),
      emails_per_day_limit: (ENV['EMAILS_PER_DAY_LIMIT'] || 1000).to_i,
      frolodex_batch_fetch_size: (ENV['FROLODEX_BATCH_FETCH_SIZE'] || 1000).to_i,
      emails_per_day_limit_enabled: !ENV['EMAILS_PER_DAY_LIMIT'].to_s.empty?
    }.freeze

    attr_accessor :base_url, :public_base_url, :api_key, :retry_times

    def initialize
      @base_url = DEFAULTS[:base_url]
      @public_base_url = DEFAULTS[:public_base_url]
      @api_key = DEFAULTS[:api_key]
      @retry_times = DEFAULTS[:retry_times]
    end
  end

  # Configure FrederickAPI, for example in an initializer or (better
  # yet) in one of the `config/environments/*.rb` files so you can have it
  # configured differently per environment. For example, you may want to use
  # staging API in staging environment, or may want different timeouts in
  # development environment than production.
  #
  # @example
  #   # config/environments/staging.rb
  #   ...
  #   FrederickAPI.configure do |c|
  #     c.base_url = 'https://api.staging.hirefrederick.com/v1'
  #     c.api_key = '1234-5678-1234-5678-1234-5678'
  #   end
  #   ...
  #
  # @yield [configuration] block to configure FrederickAPI
  # @return [FrederickAPI::Configuration] the completed configuration
  def self.configure
    yield(config)
  end

  # Returns a reference to the current configuration.
  #
  # @return [FrederickAPI::Configuration]
  def self.config
    @config ||= Configuration.new
  end
end
