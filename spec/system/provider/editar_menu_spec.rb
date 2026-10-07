# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edición de menú publicado por el proveedor", type: :system do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }

  context "con sesión iniciada como proveedor" do
    before do
      sign_in provider_user, role: :provider
    end


    it "permite editar el stock de un plato en una fecha publicada futura y persistir los cambios" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      schedule = milanesa.schedules.create!(date: target_date, amount: 10)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)

      find("button", text: /\b#{target_date.day}\b/).click

      expect(page).to have_button("Editar menú")
      click_button "Editar menú"

      expect(page).to have_content("Editando menú publicado")

      # Ajusta el stock del plato a 25
      fill_in "amount-#{milanesa.id}", with: "25"

      click_button "Publicar menú"

      expect(page).to have_content("Menú actualizado con éxito.")
      expect(schedule.reload.amount).to eq(25)
    end

    it "no permite editar un menú para fechas anteriores a la actual" do
      past_date = Date.current.beginning_of_week(:monday) - 1.week + 1.day
      milanesa.schedules.create!(date: past_date, amount: 10)

      visit schedules_path(week_start: (Date.current.beginning_of_week(:monday) - 1.week).to_s)

      find("button", text: /\b#{past_date.day}\b/).click

      expect(page).to have_no_button("Editar menú")
    end

    it "cancela automáticamente los pedidos si se retira un plato del menú publicado" do
      target_date = Date.current.next_week(:monday) + 2.days
      Schedule.where(date: target_date).destroy_all
      schedule_to_remove = milanesa.schedules.create!(date: target_date, amount: 10)

      order = Order.create!(
        consumer: consumers(:one),
        schedule: schedule_to_remove,
        status: :confirmed,
        amount: 1,
        price: 350,
        discounted_price: 175,
        address: "18 de Julio 1234",
        delivery_method: :office
      )

      second_dish = provider.menus.create!(
        name: "Wok de vegetales",
        description: "Salteado fresco",
        price: 290
      )
      second_dish.schedules.create!(date: target_date, amount: 10)

      visit schedules_path(week_start: target_date.beginning_of_week(:monday).to_s)
      find("button", text: /\b#{target_date.day}\b/).click

      click_button "Editar menú"

      # Deselecciona el plato que tenía pedidos y guarda
      find("p", text: milanesa.name).click
      click_button "Publicar menú"

      expect(page).to have_content("Menú actualizado con éxito.")
      expect(Schedule.exists?(schedule_to_remove.id)).to be(false)
      expect(order.reload.status).to eq("cancelled")
      expect(order.cancelled_by).to eq(provider_user)
    end
  end

  context "control de acceso por roles" do
    it "no permite a un empleado acceder a la pantalla de publicación y edición de menús" do
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
