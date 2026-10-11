# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Quitar un plato del menú publicado", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }

  context "con sesión iniciada como proveedor" do
    before do
      sign_in provider_user, role: :provider
    end

    it "quita un plato futuro tras confirmar y lo borra del menú" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      schedule = milanesa.schedules.create!(date: target_date, amount: 10)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      within(find("[data-slot=card]", text: milanesa.name)) { click_button "Quitar" }
      within("[role=dialog]") { click_button "Quitar" }

      expect(page).to have_content("Plato quitado del menú.")
      expect(Schedule.exists?(schedule.id)).to be(false)
    end

    it "no vuelve a aparecer al recargar si el plato sigue una agenda semanal" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      milanesa.agendas.create!(weekdays: [ target_date.cwday ], starts_on: Date.current, amount: 10)
      Menus::AgendaScheduler.call(milanesa)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      within(find("[data-slot=card]", text: milanesa.name)) { click_button "Quitar" }
      within("[role=dialog]") { click_button "Quitar" }
      expect(page).to have_content("Plato quitado del menú.")

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      expect(page).to have_no_content(milanesa.name)
    end

    it "no quita nada si se cancela la confirmación" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      schedule = milanesa.schedules.create!(date: target_date, amount: 10)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      within(find("[data-slot=card]", text: milanesa.name)) { click_button "Quitar" }
      within("[role=dialog]") { click_button "Cancelar" }

      expect(page).to have_no_css("[role=dialog]")
      expect(Schedule.exists?(schedule.id)).to be(true)
    end

    it "cancela los pedidos del plato quitado" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      schedule = milanesa.schedules.create!(date: target_date, amount: 10)

      order = Order.create!(
        consumer: consumers(:one),
        schedule:,
        status: :confirmed,
        amount: 1,
        price: 350,
        discounted_price: 175,
        address: "18 de Julio 1234",
        delivery_method: :office
      )

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      within(find("[data-slot=card]", text: milanesa.name)) { click_button "Quitar" }
      within("[role=dialog]") { click_button "Quitar" }

      expect(page).to have_content("Plato quitado del menú.")
      expect(order.reload.status).to eq("cancelled")
      expect(order.cancelled_by).to eq(provider_user)
    end

    it "no ofrece quitar platos de fechas pasadas" do
      past_date = Date.current.beginning_of_week(:monday) - 1.week + 1.day
      milanesa.schedules.create!(date: past_date, amount: 10)

      visit schedules_path(week_start: (Date.current.beginning_of_week(:monday) - 1.week).to_s)
      find("button", text: /\b#{past_date.day}\b/).click

      expect(page).to have_content(milanesa.name)
      expect(page).to have_no_button("Quitar")
      expect(page).to have_no_text("En stock")
      expect(page).to have_button("Agregar platos", disabled: true)
    end

    it "avisa que no se publicó menú en una fecha pasada sin platos y no deja agregar" do
      past_date = Date.current.beginning_of_week(:monday) - 1.week + 1.day
      Schedule.where(date: past_date).destroy_all

      visit schedules_path(week_start: (Date.current.beginning_of_week(:monday) - 1.week).to_s)
      find("button", text: /\b#{past_date.day}\b/).click

      expect(page).to have_content("No se publicó menú para este día.")
      expect(page).to have_button("Agregar platos", disabled: true)
    end

    it "muestra el aviso de día vacío cuando no hay platos publicados" do
      target_date = Date.current.next_week(:monday) + 1.day
      Schedule.where(date: target_date).destroy_all

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      expect(page).to have_content("No hay platos publicados para el")
    end

    it "filtra los platos del día con el buscador y avisa si no hay resultados" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      milanesa.schedules.create!(date: target_date, amount: 10)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      fill_in "Buscar plato...", with: "mil"
      expect(page).to have_content(milanesa.name)

      fill_in "Buscar plato...", with: "zzzz"
      expect(page).to have_content("No se encontraron resultados")
      expect(page).to have_no_content(milanesa.name)
    end
  end

  context "control de acceso por roles" do
    it "no permite a un empleado acceder a la pantalla de publicación de menús" do
      sign_in users(:one), role: :consumer

      visit schedules_path

      expect(page).to have_no_current_path(schedules_path)
    end

    it "redirige al inicio de sesión a un usuario sin autenticar" do
      visit schedules_path

      expect(page).to have_current_path(sign_in_path)
    end
  end
end
