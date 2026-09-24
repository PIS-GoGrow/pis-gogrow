# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings::Profiles", type: :request do
  fixtures :providers, :users

  describe "GET /settings/profile" do
    it "shows delivery settings only for the authenticated provider" do
      sign_in providers(:tuviandita).user, role: :provider

      get settings_profile_path

      expect(inertia).to render_component("settings/profiles/show")
      expect(inertia).to have_props(provider: hash_including(home_delivery: true))
    end

    it "does not expose delivery settings to consumers" do
      sign_in users(:one), role: :consumer

      get settings_profile_path

      expect(inertia).to have_props(provider: nil)
    end
  end

  describe "PATCH /settings/profile" do
    it "updates only the authenticated provider's home delivery setting" do
      provider = providers(:tuviandita)
      other_provider = providers(:endulzate)
      sign_in provider.user, role: :provider

      patch settings_profile_path, params: { name: provider.user.name, home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(false)
      expect(other_provider.reload.home_delivery).to be(true)
    end

    it "ignores home delivery updates outside a provider session" do
      provider = providers(:tuviandita)
      sign_in users(:one), role: :consumer

      patch settings_profile_path, params: { name: users(:one).name, home_delivery: "0" }

      expect(response).to redirect_to(settings_profile_path)
      expect(provider.reload.home_delivery).to be(true)
    end
  end
end
