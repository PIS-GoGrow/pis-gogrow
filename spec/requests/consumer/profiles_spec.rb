# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consumer::Profiles", type: :request do
  fixtures :users, :companies, :consumers, :providers, :benefit_configurations, :benefit_rules, :benefits

  describe "GET /cuenta" do
    it "redirects visitors to the sign in page" do
      get profile_path

      expect(response).to redirect_to(consumer_welcome_path)
    end

    it "redirects a provider to the home page" do
      sign_in users(:provider_user), role: :provider

      get profile_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects an admin to the home page" do
      sign_in users(:admin), role: :admin

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
          due_date: DateFormat.short(benefits(:monthly).due_date)
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

      it "lists the employee's coupons with how many meals are left" do
        coupon = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift), description: "Cupón", percentage: 30,
          amount: 3, starts_on: Date.current, due_date: Date.current + 5.days
        )
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: coupon, benefit_used: 1)

        get profile_path

        expect(inertia).to have_props(
          coupons: [ { id: coupon.id, name: "Cupón", percentage: 30, remaining: 2, period: DateFormat.short_range(Date.current, Date.current + 5.days) } ]
        )
      end

      it "does not list expired coupons" do
        consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón vencido",
          percentage: 30,
          amount: 1,
          starts_on: Date.current - 5.days,
          due_date: Date.current - 1.day,
          status: :current
        )

        get profile_path

        expect(inertia.props[:coupons]).to be_empty
      end

      it "does not list coupons with no remaining uses" do
        coupon = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón agotado",
          percentage: 30,
          amount: 1,
          starts_on: Date.current,
          due_date: Date.current + 5.days
        )

        OrderBenefit.create!(
          order: orders(:upcoming_pending_future),
          benefit: coupon,
          benefit_used: 1
        )

        get profile_path

        expect(inertia.props[:coupons]).to be_empty
      end

      it "keeps coupons with remaining uses and discards exhausted ones when multiple exist" do
        active_coupon = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón activo",
          percentage: 25,
          amount: 2,
          starts_on: Date.current,
          due_date: Date.current + 3.days
        )
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: active_coupon, benefit_used: 1)

        exhausted_coupon = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift2),
          description: "Cupón agotado",
          percentage: 40,
          amount: 1,
          starts_on: Date.current,
          due_date: Date.current + 5.days
        )
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: exhausted_coupon, benefit_used: 1)

        get profile_path

        expect(inertia.props[:coupons]).to contain_exactly(
          hash_including(
            id: active_coupon.id,
            name: "Cupón activo",
            percentage: 25,
            remaining: 1,
            period: DateFormat.short_range(Date.current, Date.current + 3.days)
          )
        )
      end

      it "does not list coupons with amount configured as zero" do
        consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón cero usos",
          percentage: 20,
          amount: 0,
          starts_on: Date.current,
          due_date: Date.current + 5.days
        )

        get profile_path

        expect(inertia.props[:coupons]).to be_empty
      end

      it "safely filters exhausted coupons and responds 200 even when unexpected query parameters are passed" do
        exhausted = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón agotado con params",
          percentage: 30,
          amount: 1,
          starts_on: Date.current,
          due_date: Date.current + 5.days
        )
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: exhausted, benefit_used: 1)

        get profile_path, params: { remaining: 0, coupon_id: "fake_id", unexpected: "bypass" }

        expect(response).to have_http_status(:ok)
        expect(inertia.props[:coupons]).to be_empty
      end

      it "does not list coupons where benefit usage equals or exceeds initial amount" do
        coupon = consumers(:one).benefits.create!(
          benefit_configuration: benefit_configurations(:gift),
          description: "Cupón sobreutilizado",
          percentage: 30,
          amount: 2,
          starts_on: Date.current,
          due_date: Date.current + 5.days
        )
        OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: coupon, benefit_used: 2)

        get profile_path

        expect(inertia.props[:coupons]).to be_empty
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
