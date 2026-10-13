# frozen_string_literal: true

module Throttling
  extend ActiveSupport::Concern

  class_methods do
    def throttle(name, to:, within:, by: -> { request.remote_ip }, **options)
      rate_limit(
        to:, within:, by:, name:, **options,
        store: Rails.configuration.x.rate_limit_store || Rails.cache,
        with: -> { redirect_back_or_to provider_sign_in_path, alert: t("flash.too_many_attempts") }
      )
    end
  end
end
