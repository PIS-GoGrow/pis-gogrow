# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pedidos futuros en deuda y cobros", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }

  it "no incluye pedidos futuros confirmados en la deuda ni en las viandas entregadas hasta el día de su entrega" do
    sign_in consumer_user, role: :consumer
    visit accounts_path

    expect(page).to have_content("Tu consumo")
    expect(page).to have_content("$150,25")
    expect(page).to have_content("(1 vianda)")

    click_button "Ver detalle del consumo"
    within("[role=dialog]") do
      expect(page).to have_content("Milanesa")
      expect(page).to have_content("$150,25")
      click_button "Cerrar"
    end
    expect(page).to have_no_selector("[role=dialog]")

    sign_in provider_user, role: :provider
    visit provider_collections_path

    expect(page).to have_content("1 vianda entregada")

    future_order = orders(:upcoming_confirmed_future)
    future_date = future_order.delivery_date

    travel_to future_date.in_time_zone("Montevideo").change(hour: 0, min: 5)
    DeliveredOrdersSyncJob.perform_now

    sign_in consumer_user, role: :consumer
    visit accounts_path

    expect(page).to have_content("$450,75")
    expect(page).to have_content("(3 viandas)")

    sign_in provider_user, role: :provider
    visit provider_collections_path

    expect(page).to have_content("4 viandas entregadas")
  end
end
