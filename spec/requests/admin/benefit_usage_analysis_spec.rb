# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::BenefitUsage analysis", type: :request do
  before { allow(Date).to receive(:current).and_return(Date.new(2032, 4, 17)) }

  it "requires a session" do
    get admin_benefit_usage_analysis_path
    expect(response).to redirect_to(admin_welcome_path)
  end

  { one: :consumer, provider_user: :provider }.each do |user, role|
    it "rejects #{role}" do
      sign_in(users(user), role: role)
      get admin_benefit_usage_analysis_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "as HR" do
    before { sign_in users(:admin), role: :admin }

    it "renders the page and twelve months without computing stats or calling AI" do
      expect(AdminBenefitUsageStats).not_to receive(:new)
      expect(AdminBenefitUsageSummary).not_to receive(:new)
      get admin_benefit_usage_analysis_path
      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("admin/benefit_usage/analysis")
      expect(inertia).to have_props(month: "2032-04", current_month: "2032-04")
      expect(inertia).to have_props { |props|
        props[:months].map { it[:key] } == 12.times.map { (Date.new(2032, 4, 1) << it).strftime("%Y-%m") }
      }
    end

    it "keeps historical URLs outside the initial twelve months" do
      get admin_benefit_usage_analysis_path, params: { month: "2020-01" }
      expect(inertia).to have_props(month: "2020-01")
      expect(inertia).to have_props { |props|
        props[:months].size == 13 && props[:months].last[:key] == "2020-01"
      }
    end

    it "keeps a selected month on reload" do
      2.times do
        get admin_benefit_usage_analysis_path, params: { month: "2032-03" }
        expect(inertia).to have_props(month: "2032-03")
      end
    end

    it "canonicalizes malformed or future periods" do
      [ "2032-05", "2032-4", "0000-01", "invalid" ].each do |month|
        get admin_benefit_usage_analysis_path, params: { month: }
        expect(response).to redirect_to(admin_benefit_usage_analysis_path)
      end
    end
  end
end
