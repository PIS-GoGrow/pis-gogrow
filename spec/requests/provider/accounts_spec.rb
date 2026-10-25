# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Accounts", type: :request do
  fixtures :users, :providers, :admins

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

    it "redirects admins to the root page" do
      sign_in users(:admin), role: :admin

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

    it "expone incomplete_sections como un array vacío cuando las 4 secciones están configuradas" do
      sign_in users(:provider_user), role: :provider
      providers(:tuviandita).update_columns(
        payment_details_configured_at: Time.current,
        order_deadline_configured_at: Time.current,
        deliveries_configured_at: Time.current,
        notifications_configured_at: Time.current
      )

      get provider_account_path

      expect(inertia).to have_props(incomplete_sections: [])
    end

    it "expone todas las 4 secciones en incomplete_sections cuando ninguna está configurada" do
      sign_in users(:provider_user), role: :provider
      providers(:tuviandita).update_columns(
        payment_details_configured_at: nil,
        order_deadline_configured_at: nil,
        deliveries_configured_at: nil,
        notifications_configured_at: nil
      )

      get provider_account_path

      expect(inertia).to(have_props do |props|
        props["incomplete_sections"] == %w[payment_details operational_settings deliveries notifications]
      end)
    end
  end
end
