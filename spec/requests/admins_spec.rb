# frozen_string_literal: true

require "rails_helper"

require "inertia_rails/rspec"

RSpec.describe "Admins", type: :request do
  fixtures :users, :companies, :providers, :consumers

  let(:admin_user) do
    user = User.create!(name: "Admin User", email: "admin@gogrow.com", password: "password123456")
    Admin.create!(user:, company: companies(:gogrow))
    user
  end

  describe "GET /admin/dashboard" do
    it "redirects visitors without a session to the sign in page" do
      get admin_dashboard_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the root page" do
      sign_in users(:one), role: :consumer

      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects a provider to the root page" do
      sign_in users(:provider_user), role: :provider

      get admin_dashboard_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the admin dashboard for an authenticated admin" do
      sign_in admin_user, role: :admin

      get admin_dashboard_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("admin/dashboard/index")
    end
  end
end
