# frozen_string_literal: true

# cooldown: don't resolve gem versions newer than 7 days, giving time for
# malicious releases to be detected and yanked.
# https://blog.rubygems.org/2026/06/03/cooldown-let-new-gems-be-vetted.html
source "https://rubygems.org", cooldown: 7

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use pg as the database for Active Record
gem "pg", "~> 1.6", ">= 1.6.2"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false, group: [ :development, :deploy ]

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "rails_vite" # Vite integration [https://github.com/skryukov/rails_vite]

# Dashboard for Active Job / Solid Queue [https://github.com/rails/mission_control-jobs]
gem "mission_control-jobs"

# The Rails adapter for Inertia.js [https://inertia-rails.dev]
gem "inertia_rails", "~> 3.21"

# An authentication system generator for Rails applications
# we leave gem here to watch for security updates
gem "authentication-zero"

# Brings Rails named routes to javascript
gem "typelizer"

# Export Rails i18n translations to JSON for the frontend
gem "i18n-js", "~> 4.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec for Rails 7+
  gem "rspec-rails", "~> 8.0"

  # Fixtures replacement with a straightforward definition syntax
  gem "factory_bot_rails"

  gem "faker"

  gem "dotenv-rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Use letter_opener to preview emails in the browser in development [https://github.com/ryanb/letter_opener]
  gem "letter_opener"
  gem "listen", "~> 3.10"

  gem "annotaterb", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
gem "alba"
gem "alba-inertia"

# Google Sign-In for the provider login flow
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

gem "sentry-ruby", "~> 6.5"
gem "sentry-rails", "~> 6.5"
