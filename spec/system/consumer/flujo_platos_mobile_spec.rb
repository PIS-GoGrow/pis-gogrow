# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Flujo mobile de selección de platos del empleado", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :menu_option_groups,
           :benefit_configurations, :benefits

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:tuesday) { monday + 1.day }
  let(:sorrentinos) { menus(:sorrentinos) }
  let(:milanesa) { menus(:milanesa) }

  before do
    page.current_window.resize_to(375, 667)

    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    Schedule.create!(menu: sorrentinos, date: monday, amount: 10)
    Schedule.create!(menu: milanesa, date: tuesday, amount: 10)

    sign_in users(:one), role: :consumer
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def calm_animations
    page.execute_script(<<~JS)
      document.querySelectorAll("*").forEach((el) => {
        el.style.animation = "none";
        el.style.transition = "none";
      });
    JS
  end

  def pick_option(group_name, option)
    find("section", text: "Elegí tu/s #{group_name.downcase}").find("label", text: option).click
  end

  it "completa el flujo en mobile: filtro con ícono nuevo, badge Agregado, fechas en carrito y confirmación con Hugeicons" do
    visit_hydrated dashboard_path
    calm_animations

    # 1. Filtro de proveedores con ícono Settings2
    filter_button = find("button[aria-label='Filtrar por proveedores']")
    expect(filter_button).to be_visible
    within(filter_button) do
      expect(page).to have_css("svg.lucide-settings-2")
    end

    # 2. Abrir plato con opciones y verificar título neutro en minúscula
    find_button("Agregar #{sorrentinos.name}").click
    calm_animations
    expect(page).to have_content("Notas para este plato")

    expect(page).to have_content("Elegí tu/s salsa")
    expect(page).to have_content("Elegí tu/s relleno")

    # Seleccionar opciones obligatorias/opcionales
    pick_option("Salsa", "Bolognesa")
    pick_option("Relleno", "Espinaca y queso")
    click_button "Agregar"
    calm_animations

    # 3. "Agregado": píldora azul en el menú y arriba en el detalle del plato
    expect(page).to have_content("Agregado")
    sorrentinos_btn = find_button("Agregar #{sorrentinos.name}")
    expect(sorrentinos_btn).to have_text("1")

    # Reabrir el plato y verificar que la píldora aparece en el encabezado
    sorrentinos_btn.click
    calm_animations
    expect(page).to have_content("Notas para este plato")
    expect(page).to have_content("Agregado")
    find_button("Volver").click
    calm_animations

    # 4. Carrito con platos del mismo día: fecha de entrega va debajo de "Tu carrito"
    click_link "Ver carrito"
    calm_animations

    expect(page).to have_content("Tu carrito")
    expect(page).to have_content(/Entrega: Lunes #{monday.day} de/i)

    # Volver al menú para agregar un plato de otro día
    find_button("Volver").click
    calm_animations

    # Navegar al martes en el menú semanal
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{tuesday.day}\b/).click }
    calm_animations
    find_button("Agregar #{milanesa.name}").click
    calm_animations
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"
    calm_animations

    # Volver al carrito con platos de dos días distintos
    click_link "Ver carrito"
    calm_animations

    expect(page).to have_content(/Entrega: Lunes #{monday.day} de/i)
    expect(page).to have_content(/Entrega: Martes #{tuesday.day} de/i)

    # 5. Confirmación del pedido: tick y botón "Ir a Mis pedidos"
    click_button "Confirmar pedido"
    calm_animations

    expect(page).to have_content("¡Pedido recibido!")
    expect(page).to have_content("Te notificaremos cuando el proveedor confirme tu pedido.")
    expect(page).to have_link("Ir a Mis pedidos", href: orders_path)

    # El toast de Sonner ("Pedido confirmado") se superpone brevemente sobre el botón en mobile (375px).
    page.execute_script("document.querySelectorAll('[data-sonner-toaster]').forEach(el => el.remove())")
    click_link "Ir a Mis pedidos"
    expect(page).to have_current_path(orders_path)
    expect(page).to have_content("Mis pedidos")
  end
end
