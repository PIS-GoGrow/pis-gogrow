# frozen_string_literal: true

# Historia IBP-083 "Como EMPLEADO, quiero recibir una notificación cuando esté por
# vencer el plazo para hacer pedidos si no tengo ningún pedido realizado para no
# olvidarme de ordenar una vianda." La parte que ve el empleado: el banner con el
# mensaje (CA6) y cerrarlo (CA5). Las reglas de horario, pedidos y duplicados están
# en spec/services/order_reminders/generate_spec.rb.

require "rails_helper"

RSpec.describe "Recordatorio de pedido", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:message) { "¡No te quedes sin almuerzo! Todavía no pediste tu vianda de hoy." }

  before do
    Notification::Configuration.find_or_create_by!(key: "order_reminders") do |configuration|
      configuration.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)

    providers(:tuviandita).update!(order_deadline: "12:00")
    providers(:endulzate).update!(order_deadline: "13:00")
  end

  # Lo que hace el job de cada minuto cuando entra en la hora previa al cierre.
  def run_reminders
    date = Date.current
    OrderReminders::Generate.call(date:, now: Time.zone.local(date.year, date.month, date.day, 11))
  end

  def visit_dashboard_as(user)
    sign_in user, role: :consumer
    visit dashboard_path
    expect(page).to have_content("Hola,")
  end

  it "le muestra el recordatorio al empleado sin pedido y no vuelve después de cerrarlo" do
    run_reminders
    visit_dashboard_as users(:other_consumer_user)
    expect(page).to have_content(message)

    click_button "Cerrar notificación"
    expect(page).to have_no_content(message)

    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(message)

    sign_out
    run_reminders
    visit_dashboard_as users(:other_consumer_user)
    expect(page).to have_no_content(message)
  end

  it "no se lo muestra a un empleado que ya pidió para hoy" do
    run_reminders

    visit_dashboard_as users(:one)

    expect(page).to have_no_content(message)
  end
end
