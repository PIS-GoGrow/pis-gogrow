# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ciclo de vida continuo de beneficios", type: :request do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus,
           :benefit_configurations, :benefit_rules, :benefits

  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }

  after do
    travel_back
  end

  it "encadena el ciclo completo: consulta inicial (50%), programación por RRHH (70%), transición temporal con jobs y validación del nuevo beneficio" do
    initial_monday = Date.current.next_occurring(:monday).noon
    travel_to(initial_monday)

    benefits(:monthly).update!(
      due_date: Date.current.end_of_month,
      status: :current,
      percentage: 50,
      amount: 20
    )

    # -----------------------------------------------------------------
    # Paso 1 (Empleado): Inicia sesión y consulta beneficio inicial (50%)
    # -----------------------------------------------------------------
    sign_in consumer_user, role: :consumer
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(inertia.props[:benefit][:percentage]).to eq(50)
    expect(inertia.props[:benefit][:monthly_limit]).to eq(20)

    # -----------------------------------------------------------------
    # Paso 2 (RRHH): Inicia sesión y programa nuevo beneficio (70%)
    # -----------------------------------------------------------------
    sign_in admin_user, role: :admin
    post admin_benefit_configurations_path, params: {
      benefit_configuration: {
        subsidy_percentage: 70,
        max_voucher_price: 300,
        monthly_voucher_limit: 15
      }
    }

    expect(response).to redirect_to(admin_benefit_configurations_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)

    new_config = BenefitConfiguration.joins(:benefit_rules)
                                     .where(benefit_rules: { effective_from: Date.current.next_month.beginning_of_month })
                                     .last
    expect(new_config).to be_present
    expect(new_config.subsidy_percentage).to eq(70)

    # -----------------------------------------------------------------
    # Paso 3 (Transición temporal): travel_to al próximo mes y jobs
    # -----------------------------------------------------------------
    next_period_monday = Date.current.next_month.beginning_of_month.next_occurring(:monday).noon
    travel_to(next_period_monday)

    BenefitExpirationJob.perform_now
    BenefitAssignationJob.perform_now

    expect(benefits(:monthly).reload.status).to eq("expired")
    new_benefit = consumer_user.consumer.reload.current_monthly_benefit
    expect(new_benefit).to be_present
    expect(new_benefit.percentage).to eq(70)
    expect(new_benefit.amount).to eq(15)

    # -----------------------------------------------------------------
    # Paso 4 (Empleado): Vuelve a consultar y valida nuevo beneficio
    # -----------------------------------------------------------------
    sign_in consumer_user, role: :consumer
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(inertia.props[:benefit][:percentage]).to eq(70)
    expect(inertia.props[:benefit][:monthly_limit]).to eq(15)
  end
end
