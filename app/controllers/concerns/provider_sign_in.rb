# frozen_string_literal: true

module ProviderSignIn
  extend ActiveSupport::Concern

  private

  def start_provider_session(user)
    reset_session
    record = user.sessions.create!(role: :provider)
    cookies.signed.permanent[:session_token] = { value: record.id, httponly: true }
  end
end
