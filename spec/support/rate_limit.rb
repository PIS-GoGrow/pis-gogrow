# frozen_string_literal: true

RSpec.configure do |config|
  config.before { Rails.configuration.x.rate_limit_store.clear }
end
