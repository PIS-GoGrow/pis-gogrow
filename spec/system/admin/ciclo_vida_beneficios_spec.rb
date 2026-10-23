# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ciclo de vida de beneficios multi-rol", type: :system do
  fixtures :users, :companies, :consumers, :admins, :providers, :menus, :reviews,
           :benefit_configurations, :benefit_rules, :benefits

  let(:consumer_user) { users(:one) }
  let(:admin_user) { users(:admin) }
  let(:sorrentinos) { menus(:sorrentinos) }
  let(:office_menu) { menus(:office_menu) }

  after do
    travel_back
  end

  def open_dish(menu)
    btn = find("button[aria-label='Agregar #{menu.name}']", wait: 15)
    btn.click
    unless page.has_button?("Volver", wait: 5)
      btn.click
    end
  end

  def open_editor
    click_button "Editar"
    unless page.has_field?("subsidy_percentage", wait: 2)
      click_button "Editar"
    end
  end

  it "encadena el ciclo continuo entre Empleado y RRHH a lo largo del tiempo" do
    initial_monday = Date.current.next_occurring(:monday).noon
    travel_to(initial_monday)

    Order.destroy_all
    Schedule.delete_all
    # El beneficio future de benefits.yml vence hoy + 10: según el día cae después del
    # lunes del mes siguiente y le gana al beneficio que asignan los jobs.
    benefits(:future).destroy

    benefits(:monthly).update!(
      due_date: Date.current.end_of_month,
      status: :current,
      percentage: 50,
      amount: 20
    )

    Schedule.create!(menu: sorrentinos, date: Date.current, amount: 10)

    # -------------------------------------------------------------
    # Paso 1 (Empleado): Inicia sesión, consulta el plato y ve 50%
    # -------------------------------------------------------------
    sign_in consumer_user, role: :consumer
    visit dashboard_path

    expect(page).to have_content("Sorrentinos artesanales")
    open_dish(sorrentinos)

    expect(page).to have_content("Subsidio Base (50%)")
    expect(page).to have_content("Monto a pagar")
    expect(page).to have_content("$160")

    sign_out

    # -------------------------------------------------------------
    # Paso 2 (RRHH): Inicia sesión y programa nuevo beneficio (70%)
    # -------------------------------------------------------------
    sign_in admin_user, role: :admin
    visit admin_benefit_configurations_path

    open_editor
    fill_in "subsidy_percentage", with: "70"
    fill_in "max_voucher_price", with: "300"
    fill_in "monthly_voucher_limit", with: "15"

    click_button "Programar Subsidio"
    date = Calendar.new.configurable_month.strftime("%d/%m/%y")
    expect(page).to have_content("Hay un cambio programado para el " + date, wait: 30)

    sign_out

    # -------------------------------------------------------------
    # Paso 3 (Transición temporal): travel_to y ejecución de jobs
    # -------------------------------------------------------------
    next_period_monday = Date.current.next_month.beginning_of_month.next_occurring(:monday).noon
    travel_to(next_period_monday)

    BenefitUpdateJob.perform_now
    BenefitAssignationJob.perform_now

    expect(benefits(:monthly).reload.status).to eq("expired")
    new_benefit = consumer_user.consumer.reload.current_monthly_benefit
    expect(new_benefit).to be_present
    expect(new_benefit.percentage).to eq(70)
    expect(new_benefit.amount).to eq(15)

    Schedule.create!(menu: sorrentinos, date: Date.current, amount: 10)
    Schedule.create!(menu: office_menu, date: Date.current, amount: 10)

    # -------------------------------------------------------------
    # Paso 4 (Empleado): Vuelve a consultar y valida nuevo precio
    # -------------------------------------------------------------
    sign_in consumer_user, role: :consumer
    visit dashboard_path

    expect(page).to have_content("Sorrentinos artesanales")
    expect(page).to have_content("Ensalada de quinoa")
    open_dish(sorrentinos)

    # El límite de precio es 300, los sorrentinos no se subsidian pero la ensalada sí
    expect(page).to have_no_content("Subsidio base")
    expect(page).to have_content("Monto a pagar")
    expect(page).to have_content("$320")

    visit dashboard_path
    open_dish(office_menu)

    expect(page).to have_content("Subsidio base (70%)")
    expect(page).to have_content("- $175")
    expect(page).to have_content("Monto a pagar")
    expect(page).to have_content("$75")
  end
end
