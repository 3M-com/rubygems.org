source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.0.2"
gem "rails-i18n", "~> 8.0.1"

gem "aws-sdk-s3", "~> 1.195"
gem "aws-sdk-sqs", "~> 1.99"
gem "bootsnap", "~> 1.18"
gem "clearance", "~> 2.10"
gem "dalli", "~> 3.2"
gem "datadog", "~> 2.19"
gem "dogstatsd-ruby", "~> 5.7"
gem "google-protobuf", "~> 4.31"
gem "faraday", "~> 2.13"
gem "faraday-retry", "~> 2.3"
gem "faraday-restrict-ip-addresses", "~> 0.3.0", require: "faraday/restrict_ip_addresses"
gem "flipper", "~> 1.3"
gem "flipper-active_record", "~> 1.3"
gem "flipper-ui", "~> 1.3"
gem "good_job", "~> 3.99"
gem "gravtastic", "~> 3.2"
gem "honeybadger", "~> 6.0.2", require: false # see https://github.com/rubygems/rubygems.org/pull/4598
gem "http_accept_language", "~> 2.1"
gem "kaminari", "~> 1.2"
gem "mail", "~> 2.8"
gem "octokit", "~> 10.0"
gem "omniauth-github", "~> 2.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "openid_connect", "~> 2.3"
gem "pg", "~> 1.6"
gem "puma", "~> 6.6"
gem "rack", "~> 3.2"
gem "rackup", "~> 2.2"
gem "rack-sanitizer", "~> 2.0"
gem "rbtrace", "~> 0.5.2"
gem "rdoc", "~> 6.14"
gem "roadie-rails", "~> 3.3"
gem "ruby-magic", "~> 0.6"
gem "shoryuken", "~> 6.2", require: false
gem "statsd-instrument", "~> 3.9"
gem "validates_formatting_of", "~> 0.9"
gem "opensearch-ruby", "~> 3.4"
gem "searchkick", "~> 5.5"
gem "faraday_middleware-aws-sigv4", "~> 1.0"
gem "xml-simple", "~> 1.1"
gem "compact_index", "~> 0.15.0"
gem "rack-attack", "~> 6.6"
gem "rqrcode", "~> 3.1"
gem "rotp", "~> 6.2"
gem "unpwn", "~> 1.0"
gem "webauthn", "~> 3.4"
gem "browser", "~> 6.2"
gem "bcrypt", "~> 3.1"
gem "maintenance_tasks", "~> 2.12"
gem "strong_migrations", "~> 2.5"
gem "phlex-rails", "~> 1.2"
gem "discard", "~> 1.4"
gem "user_agent_parser", "~> 2.20"
gem "pghero", "~> 3.7"
gem "faraday-multipart", "~> 1.1"
gem "sigstore", "~> 0.2.1"
gem "kramdown", "~> 2.5"
gem "zlib", "~> 3.2"

# Admin dashboard
gem "avo", "~> 3.13"
gem "pagy", "~> 8.4"
gem "view_component", "~> 3.23.2"
gem "pundit", "~> 2.5"
gem "chartkick", "~> 5.2"
gem "groupdate", "~> 6.7"
gem "prop_initializer", "~> 0.2"

group :avo, optional: true do
  source "https://packager.dev/avo-hq/" do
    gem "avo-advanced", "~> 3.22"
  end
end

# Logging
gem "amazing_print", "~> 1.8"
gem "rails_semantic_logger", "~> 4.18"
gem "pp", "0.6.2"

# Former default gems
gem "csv", "~> 3.3" # zeitwerk-2.6.12
gem "observer", "~> 0.1.2" # launchdarkly-server-sdk-8.0.0

# Assets
gem "propshaft", "~> 1.2.1"
gem "importmap-rails", "~> 2.1"
gem "stimulus-rails", "~> 1.3" # this adds stimulus-loading.js so it must be available at runtime
gem "local_time", "~> 3.0"
gem "better_html", "~> 2.1"

group :assets, :development do
  gem "tailwindcss-rails", "~> 4.3"
end

group :development, :test do
  gem "pry-byebug", "~> 3.11"
  gem "toxiproxy", "~> 2.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "dotenv-rails", "~> 3.1"
  gem "lookbook", "~> 2.3"

  gem "brakeman", "~> 7.1", require: false

  # used to find n+1 queries
  gem "prosopite", "~> 2.1"
  gem "pg_query", "~> 6.1"

  # bundle show | rg rubocop | cut -d' ' -f4 | xargs bundle update
  gem "rubocop", "~> 1.79", require: false
  gem "rubocop-rails", "~> 2.32", require: false
  gem "rubocop-performance", "~> 1.25", require: false
  gem "rubocop-minitest", "~> 0.38", require: false
  gem "rubocop-capybara", "~> 2.22", require: false
  gem "rubocop-factory_bot", "~> 2.27", require: false
end

group :development do
  gem "rails-erd", "~> 1.7"
  gem "listen", "~> 3.9"
  gem "letter_opener", "~> 1.10"
  gem "letter_opener_web", "~> 3.0"
  gem "derailed_benchmarks", "~> 2.2"
  gem "memory_profiler", "~> 1.1"
end

group :test do
  gem "datadog-ci", "~> 1.21"
  gem "minitest", "~> 5.25", require: false
  gem "minitest-retry", "~> 0.2.5"
  gem "capybara", "~> 3.40"
  gem "launchy", "~> 3.1"
  gem "rack-test", "~> 2.2", require: "rack/test"
  gem "rails-controller-testing", "~> 1.0"
  gem "mocha", "~> 2.7", require: false
  gem "shoulda-context", "~> 3.0.0.rc1"
  gem "shoulda-matchers", "~> 6.5"
  gem "selenium-webdriver", "~> 4.34"
  gem "webmock", "~> 3.25"
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-cobertura", "~> 3.0", require: false
  gem "aggregate_assertions", "~> 0.2.0"
  gem "minitest-gcstats", "~> 1.3"
  gem "minitest-reporters", "~> 1.7"
  gem "gem_server_conformance", "~> 0.1.4"
end

gem "avo_upgrade", "~> 0.1.1", group: :development
