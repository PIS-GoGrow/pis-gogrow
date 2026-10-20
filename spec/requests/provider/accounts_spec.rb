# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Accounts", type: :request do
  fixtures :users, :providers

  describe "GET /provider/cuenta" do
    it "redirects visitors without a session to the sign in page" do
      get provider_account_path

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_account_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the account screen for a provider" do
      sign_in users(:provider_user), role: :provider

      get provider_account_path

      expect(inertia).to render_component("provider/accounts/show")
    end

    it "expone las secciones incompletas en las props" do
      sign_in users(:provider_user), role: :provider
      providers(:tuviandita).update_columns(payment_details_configured_at: nil)

      get provider_account_path

      expect(inertia).to(have_props do |props|
        props["incomplete_sections"].is_a?(Array) &&
          props["incomplete_sections"].include?("payment_details") &&
          !props["incomplete_sections"].include?("deliveries")
      end)
    end
  end
end
