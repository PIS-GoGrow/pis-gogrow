# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Dashboard", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers

  describe "GET /admin/dashboard" do
    context "when visitor is unauthenticated" do
      it "redirects to the sign in page" do
        get admin_dashboard_path

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when signed in with unauthorized roles" do
      it "redirects a consumer to the root page with alert" do
        sign_in users(:one), role: :consumer

        get admin_dashboard_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end

      it "redirects a provider to the root page with alert" do
        sign_in users(:provider_user), role: :provider

        get admin_dashboard_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end
    end

    context "when signed in as admin" do
      before { sign_in users(:admin), role: :admin }

      it "renders the admin dashboard page with exact props" do
        get admin_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("admin/dashboard/index")
        expect(inertia.props[:today]).to eq(I18n.l(Date.current, format: "%A %-d de %B").capitalize)
        expect(inertia.props[:payment_month]).to eq(I18n.l(Date.current, format: "%B").downcase)
      end

      it "includes the admin role in the shared auth session props" do
        get admin_dashboard_path

        expect(inertia.props.dig(:auth, :session, :role)).to eq("admin")
      end

      it "handles unexpected query parameters safely without error" do
        get admin_dashboard_path, params: { unexpected: "malicious_input", search: "<script>alert(1)</script>" }

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("admin/dashboard/index")
      end
    end
  end
end
