# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Deliveries", type: :request do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:provider) { providers(:tuviandita) }

  describe "GET /provider/entregas" do
    it "redirects visitors without a session to the sign in page" do
      get provider_deliveries_path

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_deliveries_path

      expect(response).to redirect_to(root_path)
    end

    it "shows the signed-in provider's delivery setting" do
      sign_in users(:office_provider_user), role: :provider

      get provider_deliveries_path

      expect(inertia).to render_component("provider/deliveries/show")
      expect(inertia).to have_props { |props| props["provider"]["home_delivery"] == false }
    end
  end

  describe "PATCH /provider/entregas" do
    it "redirects to sign in without a session" do
      patch provider_deliveries_path, params: { home_delivery: false }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    it "redirects a consumer to the home page without touching any provider" do
      sign_in users(:one), role: :consumer

      patch provider_deliveries_path, params: { home_delivery: false }

      expect(response).to redirect_to(root_path)
      expect(provider.reload.home_delivery).to be(true)
    end

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "saves office only and shows it back with a notice" do
        patch provider_deliveries_path, params: { home_delivery: false }

        expect(response).to redirect_to(provider_deliveries_path)
        expect(provider.reload.home_delivery).to be(false)
        follow_redirect!
        expect(inertia).to have_props { |props| props["provider"]["home_delivery"] == false }
        expect(inertia).to have_flash(notice: I18n.t("flash.deliveries_updated"))
      end

      it "turns home delivery back on" do
        provider.update!(home_delivery: false)

        patch provider_deliveries_path, params: { home_delivery: true }, as: :json

        expect(provider.reload.home_delivery).to be(true)
      end

      it "only changes the signed-in provider's setting" do
        patch provider_deliveries_path, params: { home_delivery: false }

        expect(providers(:endulzate).reload.home_delivery).to be(true)
        expect(providers(:office_provider).reload.home_delivery).to be(false)
      end

      it "keeps published menus and existing orders as they were" do
        schedule = schedules(:future)
        order = orders(:upcoming_pending_future)

        patch provider_deliveries_path, params: { home_delivery: false }

        expect(provider.reload.home_delivery).to be(false)
        expect(schedule.reload).to have_attributes(menu: menus(:milanesa), amount: 10)
        expect(order.reload).to have_attributes(delivery_method: "home", address: "Julio Herrera y Reissig 565")
      end
    end
  end
end
