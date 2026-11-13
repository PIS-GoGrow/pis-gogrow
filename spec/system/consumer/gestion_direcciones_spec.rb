# frozen_string_literal: true

require "rails_helper"

# IBP-113: Como EMPLEADO, quiero gestionar mis direcciones de entrega guardadas
# para utilizarlas fácilmente en mis pedidos.
RSpec.describe "Gestión de direcciones de entrega", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  let(:employee) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:office_address) { companies(:gogrow).address }

  let!(:home_address) do
    consumer.saved_addresses.find_or_create_by!(name: "Casa") do |addr|
      addr.street = "Ellauri 1234"
      addr.apartment = "Apto 101"
    end
  end

  def click_until(expected_text, locator = nil, **find_args)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop do
        btn = locator ? find_button(locator, **find_args) : find(:button, **find_args)
        btn.click
        break if page.has_content?(expected_text, wait: 1)
      rescue Capybara::ElementNotFound
      end
    end
  end

  before do
    sign_in employee, role: :consumer
  end

  # Criterio 1: El empleado puede ver sus direcciones registradas.
  it "muestra la oficina no editable y las direcciones personales guardadas" do
    visit delivery_addresses_path
    without_animations

    expect(page).to have_content("Direcciones")
    expect(page).to have_content("Oficina")
    expect(page).to have_content(office_address)
    expect(page).not_to have_button("Editar Oficina")

    expect(page).to have_content("Casa")
    expect(page).to have_content("Ellauri 1234, Apto 101")
    expect(page).to have_button("Editar Casa")
  end

  # Criterio 2: El empleado puede registrar una nueva dirección.
  it "permite registrar una nueva dirección y la muestra en la lista" do
    visit delivery_addresses_path
    without_animations

    click_until("Agregar una dirección", "Agregar dirección")

    within("[role=dialog]") do
      fill_in "Nombre", with: "Gimnasio"
      fill_in "Dirección", with: "Bulevar Artigas 1234"
      fill_in "Piso/Apartamento (opcional)", with: "Piso 2"
      click_button "Agregar"
    end

    expect(page).to have_content("Gimnasio")
    expect(page).to have_content("Bulevar Artigas 1234, Piso 2")
    expect(consumer.saved_addresses.find_by(name: "Gimnasio")).to be_present
  end

  # Criterio 3: El empleado puede modificar una dirección existente, y los pedidos
  # realizados previamente con esa dirección mantienen los datos originales.
  it "permite modificar una dirección existente sin alterar pedidos anteriores" do
    order = Order.create!(
      consumer: consumer,
      schedule: schedules(:future),
      amount: 1,
      price: 300,
      discounted_price: 150,
      address: home_address.full_address,
      delivery_method: :home,
      status: :pending
    )

    visit delivery_addresses_path
    without_animations

    click_until("Editar dirección", "Editar Casa")

    within("[role=dialog]") do
      fill_in "Nombre", with: "Casa de Verano"
      fill_in "Dirección", with: "Rambla Gandhi 500"
      fill_in "Piso/Apartamento (opcional)", with: "Apto 801"
      click_button "Guardar cambios"
    end

    expect(page).to have_content("Casa de Verano")
    expect(page).to have_content("Rambla Gandhi 500, Apto 801")
    expect(page).not_to have_content("Ellauri 1234")

    expect(order.reload.address).to eq("Ellauri 1234, Apto 101")
  end

  # Criterio 4: El empleado puede eliminar una dirección desde su edición, y los
  # pedidos realizados previamente permanecen incambiados.
  it "permite eliminar una dirección desde la edición sin alterar pedidos anteriores" do
    order = Order.create!(
      consumer: consumer,
      schedule: schedules(:future),
      amount: 1,
      price: 300,
      discounted_price: 150,
      address: home_address.full_address,
      delivery_method: :home,
      status: :pending
    )

    visit delivery_addresses_path
    without_animations

    click_until("Editar dirección", "Editar Casa")

    within("[role=dialog]") do
      click_button "Eliminar"
    end

    expect(page).to have_content("¿Eliminar Casa?")
    click_button "Eliminar dirección"

    expect(page).to have_content("Dirección eliminada")
    click_button "Listo"

    expect(page).not_to have_content("Casa")
    expect(DeliveryAddress.exists?(home_address.id)).to be(false)
    expect(order.reload.address).to eq("Ellauri 1234, Apto 101")
  end
end
