# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::OperationalSettings", type: :request do
  fixtures :users, :providers

  describe "GET /provider/operational_settings" do
    it "redirects visitors without a session to the sign in page" do
      get provider_operational_settings_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_operational_settings_path

      expect(response).to redirect_to(root_path)
    end

    it "shows only the signed-in provider's deadline" do
      providers(:tuviandita).update!(order_deadline: Time.zone.parse("18:30"))
      providers(:endulzate).update!(order_deadline: Time.zone.parse("11:00"))
      sign_in users(:provider_user), role: :provider

      get provider_operational_settings_path

      expect(inertia).to render_component("provider/operational_settings/show")
      expect(inertia).to have_props(provider: { order_deadline: "18:30" })
    end

    it "sends a null deadline when none is configured" do
      providers(:tuviandita).update!(order_deadline: nil)
      sign_in users(:provider_user), role: :provider

      get provider_operational_settings_path

      expect(inertia).to have_props(provider: { order_deadline: nil })
    end
  end
end
