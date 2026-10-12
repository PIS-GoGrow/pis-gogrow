# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consumer::Profiles", type: :request do
  fixtures :users, :companies, :consumers, :providers, :benefit_configurations, :benefit_rules, :benefits

  describe "GET /profile" do
    it "redirects visitors to the sign in page" do
      get profile_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a provider to the home page" do
      sign_in users(:provider_user), role: :provider

      get profile_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as an employee" do
      before { sign_in users(:one), role: :consumer }

      it "renders the account page" do
        get profile_path

        expect(inertia).to render_component("consumer/profiles/show")
      end

      # El nombre, el email y la foto viajan en las props compartidas, así que
      # la pantalla los toma de ahí y no de las de la página.
      it "exposes the employee's name and corporate email as shared props" do
        get profile_path

        expect(inertia).to have_props { |props|
          props.dig(:auth, :user, :name) == users(:one).name &&
            props.dig(:auth, :user, :email) == users(:one).email
        }
      end

      it "exposes the benefit assigned to the employee" do
        get profile_path

        expect(inertia.props[:benefit]).to include(
          percentage: 50,
          monthly_limit: 20,
          max_price: 500.0,
          due_date: I18n.l(benefits(:monthly).due_date, format: "%d/%m/%Y")
        )
      end

      # IBP-037: la tarjeta suma al base los subsidios especiales vigentes que
      # todavía tienen usos, con tope en 100%.
      it "adds the special subsidies in force to the base benefit" do
        consumer = consumers(:one)
        consumer.benefits.create!(benefit_configuration: benefit_configurations(:seniority), description: "Antigüedad (5 años)", percentage: 25)
        used_up = consumer.benefits.create!(benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 30, amount: 1)
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: used_up, benefit_used: 1)

        get profile_path

        expect(inertia).to have_props(
          benefit_summary: { total: 75, base: 50, specials: [ { name: "Antigüedad (5 años)", percentage: 25 } ] }
        )
      end

      it "caps the combined benefit at 100%" do
        consumers(:one).benefits.create!(benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 80)

        get profile_path

        expect(inertia.props[:benefit_summary]).to include("total" => 100, "base" => 50)
      end

      it "reports how many subsidized meals are left this month" do
        get profile_path

        expect(inertia.props[:benefit][:monthly_remaining]).to eq(consumers(:one).remaining_monthly_benefit)
      end

      it "sends no benefit at all when the employee has none assigned" do
        benefits(:monthly).destroy!

        get profile_path

        expect(inertia).to have_props(benefit: nil)
        expect(inertia).to have_props(benefit_summary: nil)
      end
    end
  end
end
