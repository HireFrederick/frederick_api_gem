[ ![Codeship Status for BookerSoftwareInc/frederick_api_gem](https://app.codeship.com/projects/43a5ea40-2b13-0135-7e95-4afd89638027/status?branch=master)](https://app.codeship.com/projects/224007)

```text
 _____             _           _      _         _    ____ ___
|  ___| __ ___  __| | ___ _ __(_) ___| | __    / \  |  _ \_ _|___
| |_ | '__/ _ \/ _` |/ _ \ '__| |/ __| |/ /   / _ \ | |_) | |/ __|
|  _|| | |  __/ (_| |  __/ |  | | (__|   <   / ___ \|  __/| |\__ \
|_|  |_|  \___|\__,_|\___|_|  |_|\___|_|\_\ /_/   \_\_|  |___|___/
```


Need to connect to one of Frederick's APIs? You've come to the right
place! Need to do something else? Well, this gem's probably not gonna help you,
so, godspeed I guess.

## Installation

Put this in your Gemfile:

```ruby
gem 'frederick_api'
```

You're now ready to go with Frederick's v2 API!

### Configuring FrederickApi

You can use `FrederickApi.configure` or environment variables
to configure the Frederick API client.

```ruby
# config/initializers/frederick_api.rb
...
FrederickApi.configure do |c|
  c.base_url = 'https://api.hirefrederick.com'
  c.api_key = '1234-5678-1234-5678-1234-5678'
end
...
```

Environment variables can also be used:
  * `FREDERICK_API_BASE_URL`: Same as `base_url` above
  * `FREDERICK_API_KEY`: Same as `api_key` above
  
Environments:
  * For testing (default), use `FREDERICK_API_BASE_URL = https://api.staging.hirefrederick.com`
  * For production, use `FREDERICK_API_BASE_URL = https://api.hirefrederick.com`
  
NOTE: You must specify the production base URL of `https://api.hirefrederick.com` in order to use this gem with
Frederick's production API.
