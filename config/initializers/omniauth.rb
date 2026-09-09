# frozen_string_literal: true

# omniauth-google-oauth2 isn't auto-required by Bundler under its gem name,
# so OmniAuth::Builder can't find the strategy without this.
require "omniauth-google-oauth2"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV["GOOGLE_CLIENT_ID"],
    ENV["GOOGLE_CLIENT_SECRET"],
    scope: "email,profile"
end

OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.on_failure = proc do |env|
  OmniauthCallbacksController.action(:failure).call(env)
end
