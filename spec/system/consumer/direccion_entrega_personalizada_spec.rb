# frozen_string_literal: true

require "rails_helper"

# IBP-014 — Como EMPLEADO, quiero ingresar una dirección de entrega personalizada
# cuando el proveedor lo permita para recibir el pedido fuera de la oficina.
#
# Criterio 2 dice "[POR DEFINIR]" para los campos obligatorios: se testea contra
# lo que hoy define DeliveryAddress (nombre y dirección con número de puerta
# obligatorios, piso/apartamento opcional).
RSpec.describe "Dirección de entrega personalizada" do
  fixtures :users, :providers, :consumers, :companies

  let(:monday) { Date.current.next_week(:monday) }
  let(:office_address) { companies(:gogrow).address }

  around do |example|
    travel_to(Time.zone.local(monday.year, monday.month, monday.day, 10, 0)) { example.run }
  end

  before do
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    Provider.update_all(order_deadline: nil)
    Schedule.create!(date: monday, amount: 5, menu: Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan", price: 300))
    Schedule.create!(date: monday, amount: 5, menu: Menu.create!(provider: providers(:office_provider), name: "Ensalada de quinoa", price: 250))
  end

  def open_cart_with(*dishes, as: users(:one))
    sign_in as, role: :consumer
    visit dashboard_path
    dishes.each do |dish|
      click_button "Agregar #{dish}"
      expect(page).to have_content("Notas para este plato")
      click_button "Agregar"
    end
    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
  end

  def fill_new_address(name:, street:, apartment: "", save: false)
    click_button "Agregar"
    within("[role=dialog]", text: "Agregar una dirección") do
      fill_in "Nombre", with: name
      fill_in "Dirección", with: street
      fill_in "Piso / Apartamento (opcional)", with: apartment
      find("label", text: "Guardar esta dirección para futuros pedidos").click if save
      click_button "Agregar"
    end
  end

  # Las opciones son RadioGroupItem de Radix: un button[role=radio] dentro del label.
  def selected_address
    find("label:has([role=radio][aria-checked=true])").text
  end

  def confirm_order
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
  end

  describe "criterio 1: solo se habilita cuando el proveedor y la modalidad lo permiten" do
    it "no deja ingresar otra dirección si ningún proveedor del carrito entrega a domicilio" do
      open_cart_with("Ensalada de quinoa")

      expect(page).to have_button("Agregar", disabled: true)
      expect(page).to have_button("Ver mis direcciones", disabled: true)

      confirm_order
      expect(Order.last).to have_attributes(delivery_method: "office", address: office_address)
    end

    it "la habilita cuando el proveedor entrega a domicilio" do
      open_cart_with("Milanesa al pan")

      expect(page).to have_button("Agregar", disabled: false)
      expect(page).to have_button("Ver mis direcciones", disabled: false)
    end

    it "en un carrito mixto manda a la oficina lo del proveedor que solo entrega ahí" do
      open_cart_with("Milanesa al pan", "Ensalada de quinoa")
      fill_new_address(name: "Estudio", street: "Colonia 1370", apartment: "Apto 4")

      expect(page).to have_content("#{users(:office_provider_user).name} entrega en la Oficina")
      confirm_order

      expect(Order.find_by!(schedule: Schedule.joins(:menu).find_by!(menus: { name: "Milanesa al pan" })))
        .to have_attributes(delivery_method: "home", address: "Colonia 1370, Apto 4")
      expect(Order.find_by!(schedule: Schedule.joins(:menu).find_by!(menus: { name: "Ensalada de quinoa" })))
        .to have_attributes(delivery_method: "office", address: office_address)
    end
  end

  describe "criterio 2: solicita y valida los campos obligatorios" do
    before { open_cart_with("Milanesa al pan") }

    it "guarda la dirección para futuros pedidos y la selecciona" do
      fill_new_address(name: "Flora Café", street: "Canelones 892", apartment: "Apto 3", save: true)

      expect(page).to have_no_css("[role=dialog]", text: "Agregar una dirección")
      expect(page).to have_css("label:has([role=radio][aria-checked=true])", text: "Canelones 892, Apto 3")
      expect(selected_address).to include("Flora Café")
      expect(consumers(:one).saved_addresses.pluck(:name, :street, :apartment)).to eq([ [ "Flora Café", "Canelones 892", "Apto 3" ] ])
    end

    it "usa una dirección sin guardarla cuando no se marca guardar" do
      fill_new_address(name: "Estudio", street: "Colonia 1370")
      confirm_order

      expect(Order.last).to have_attributes(delivery_method: "home", address: "Colonia 1370")
      expect(DeliveryAddress.count).to eq(0)
    end

    {
      "nombre vacío" => { name: "", street: "Canelones 892" },
      "nombre solo con espacios" => { name: "   ", street: "Canelones 892" },
      "dirección vacía" => { name: "Casa", street: "" },
      "dirección solo con espacios" => { name: "Casa", street: "   " },
      "dirección sin número de puerta" => { name: "Casa", street: "Canelones" },
      "dirección sin calle" => { name: "Casa", street: "892" }
    }.each do |label, fields|
      it "rechaza #{label} sin guardar nada" do
        fill_new_address(**fields, save: true)

        within("[role=dialog]", text: "Agregar una dirección") do
          expect(page).to have_selector("[aria-invalid=true]")
        end
        expect(DeliveryAddress.count).to eq(0)
        expect(page).to have_content("Tu carrito")
      end
    end

    it "no deja escribir más del máximo de cada campo" do
      click_button "Agregar"
      within("[role=dialog]", text: "Agregar una dirección") do
        { "Nombre" => 40, "Dirección" => 120, "Piso / Apartamento (opcional)" => 40 }.each do |field, max|
          fill_in field, with: "Calle 1#{"a" * max}"
          expect(find_field(field).value.length).to eq(max)
        end
      end
    end
  end

  describe "criterio 3: revisar y corregir antes de confirmar" do
    before { open_cart_with("Milanesa al pan") }

    it "corrige un campo rechazado y vuelve a enviar" do
      fill_new_address(name: "Estudio", street: "Colonia")
      within("[role=dialog]", text: "Agregar una dirección") do
        fill_in "Dirección", with: "Colonia 1370"
        click_button "Agregar"
      end

      expect(page).to have_no_css("[role=dialog]", text: "Agregar una dirección")
      expect(page).to have_content("Colonia 1370")
      confirm_order
      expect(Order.last.address).to eq("Colonia 1370")
    end

    it "muestra la dirección ingresada y deja cambiarla por otra antes de confirmar" do
      fill_new_address(name: "Estudio", street: "Colonia 1307")
      expect(page).to have_css("label:has([role=radio][aria-checked=true])", text: "Colonia 1307")

      fill_new_address(name: "Estudio", street: "Colonia 1370")
      expect(page).to have_css("label:has([role=radio][aria-checked=true])", text: "Colonia 1370")
      confirm_order

      expect(Order.last.address).to eq("Colonia 1370")
    end

    it "deja volver a la oficina desde Mis direcciones" do
      fill_new_address(name: "Estudio", street: "Colonia 1370")

      click_button "Ver mis direcciones"
      within("[role=dialog]", text: "Mis direcciones") do
        find("label", text: office_address).click
        click_button "Seleccionar"
      end
      confirm_order

      expect(Order.last).to have_attributes(delivery_method: "office", address: office_address)
    end
  end

  describe "criterio 4: se guarda con el pedido y solo la ven los actores autorizados" do
    let(:order) { Order.last }

    before do
      open_cart_with("Milanesa al pan")
      fill_new_address(name: "Estudio", street: "Colonia 1370", apartment: "Apto 4")
      confirm_order
      expect(page).to have_content("Colonia 1370, Apto 4")
      sign_out
    end

    it "sobrevive a cerrar y volver a abrir sesión" do
      sign_in users(:one), role: :consumer
      visit order_path(order)

      expect(page).to have_content("Colonia 1370, Apto 4")
    end

    it "la ve el proveedor del pedido, con la misma dirección que el empleado" do
      sign_in users(:provider_user), role: :provider
      visit provider_order_path(order)

      expect(page).to have_content("Dirección de entrega")
      expect(page).to have_content("Colonia 1370, Apto 4")
    end

    it "no la ve otro proveedor entrando por URL" do
      sign_in users(:office_provider_user), role: :provider
      visit provider_order_path(order)

      expect(page).to have_no_content("Colonia 1370")
    end

    it "no la ve otro empleado entrando por URL" do
      sign_in users(:other_consumer_user), role: :consumer
      visit order_path(order)

      expect(page).to have_no_content("Colonia 1370")
    end

    it "no la ve un visitante sin sesión" do
      visit order_path(order)

      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_no_content("Colonia 1370")
    end

    it "no se ofrece a otro empleado una dirección guardada ajena" do
      consumers(:one).saved_addresses.create!(name: "Flora Café", street: "Canelones 892")
      open_cart_with("Milanesa al pan", as: users(:other_consumer_user))

      click_button "Ver mis direcciones"
      within("[role=dialog]", text: "Mis direcciones") do
        expect(page).to have_no_content("Flora Café")
        expect(page).to have_no_content("Colonia 1370")
      end
    end
  end
end
