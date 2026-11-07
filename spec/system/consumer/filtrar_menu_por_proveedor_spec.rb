# frozen_string_literal: true

require "rails_helper"

# Regresión del defecto de usabilidad del filtro de proveedores del menú
# semanal: la tarjeta visible tenía padding muerto y el toque solo funcionaba
# sobre el checkbox o el texto. Además, con "Todos" marcado, tocar un proveedor
# lo sacaba de la selección en vez de dejar solo ese.
RSpec.describe "Filtrar el menú semanal por proveedor" do
  fixtures :users, :consumers, :companies, :providers, :menus

  # Misma ventana que el resto de los specs de mobile y una semana futura
  # completa, para que el día mostrado no dependa del reloj del browser.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:tuviandita) { providers(:tuviandita) }
  let(:office_provider) { providers(:office_provider) }
  let(:endulzate) { providers(:endulzate) }

  before do
    Order.destroy_all
    Schedule.delete_all

    publish(menus(:milanesa), monday)
    publish(menus(:office_menu), monday)
    publish(menus(:sorrentinos), monday)

    page.current_window.resize_to(360, 800)
    sign_in users(:one), role: :consumer
  end

  def publish(menu, date)
    Schedule.create!(menu:, date:, amount: 5)
  end

  def open_provider_filter
    find("button[aria-label='Filtrar por proveedores']").click
    expect(page).to have_css("[data-provider-filter-sheet]")
  end

  # Toca el borde izquierdo de la fila, dentro del padding que antes era una
  # zona muerta. El control tiene que cubrir toda la fila para que seleccione.
  def tap_row_edge(provider)
    control = find("#dashboard-filter-#{provider.id}")
    row = control.find(:xpath, "..")
    width = row.native.size.width

    page.driver.browser.action
      .move_to(row.native, -(width / 2) + 4, 0)
      .click
      .perform
  end

  def expect_row_checked(provider)
    expect(page).to have_css("#dashboard-filter-#{provider.id}[aria-checked='true']")
  end

  def expect_row_unchecked(provider)
    expect(page).to have_css("#dashboard-filter-#{provider.id}[aria-checked='false']")
  end

  def filter_label
    find("span", text: /Proveedores:/)
  end

  it "selecciona el proveedor tocando el borde de la fila y filtra el menú" do
    visit_hydrated dashboard_path
    without_animations
    open_provider_filter

    selector = "#dashboard-filter-#{tuviandita.id}"
    control_width = page.evaluate_script(
      "document.querySelector('#{selector}').getBoundingClientRect().width"
    )
    row_width = page.evaluate_script(
      "document.querySelector('#{selector}').parentElement.getBoundingClientRect().width"
    )
    control_height = page.evaluate_script(
      "document.querySelector('#{selector}').getBoundingClientRect().height"
    )

    # El control es la fila entera, no solo el checkbox: alto de 48px y ancho
    # que ocupa casi todo el espacio disponible al lado de la estrella.
    expect(control_height).to be >= 48
    expect(control_width).to be > row_width * 0.7
    expect(page).to have_css("#dashboard-filter-all[aria-checked='true']")

    tap_row_edge(tuviandita)

    expect_row_checked(tuviandita)
    expect_row_unchecked(office_provider)
    expect_row_unchecked(endulzate)
    expect(page).to have_css("#dashboard-filter-all[aria-checked='false']")

    click_button "Aplicar"

    within(filter_label) do
      expect(page).to have_content(tuviandita.user.name)
      expect(page).not_to have_content(office_provider.user.name)
      expect(page).not_to have_content(endulzate.user.name)
    end
    expect(page).to have_content(menus(:milanesa).name)
    expect(page).to have_no_content(menus(:office_menu).name)
    expect(page).to have_no_content(menus(:sorrentinos).name)
  end

  it "suma proveedores, respeta la estrella y vuelve a Todos al marcar el último" do
    visit_hydrated dashboard_path
    without_animations
    open_provider_filter

    tap_row_edge(tuviandita)
    tap_row_edge(office_provider)

    expect_row_checked(tuviandita)
    expect_row_checked(office_provider)
    expect_row_unchecked(endulzate)
    expect(page).to have_css("#dashboard-filter-all[aria-checked='false']")

    # La estrella vive fuera del control: marcarla no puede cambiar la selección.
    find(
      "button[aria-label='Marcar #{endulzate.user.name} como favorito']"
    ).click

    expect_row_checked(tuviandita)
    expect_row_checked(office_provider)
    expect_row_unchecked(endulzate)
    expect(
      page
    ).to have_css(
      "button[aria-label='Quitar #{endulzate.user.name} de favoritos'][aria-pressed='true']"
    )

    click_button "Aplicar"

    within(filter_label) do
      expect(page).to have_content(tuviandita.user.name)
      expect(page).to have_content(office_provider.user.name)
      expect(page).not_to have_content(endulzate.user.name)
    end
    expect(page).to have_content(menus(:milanesa).name)
    expect(page).to have_content(menus(:office_menu).name)
    expect(page).to have_no_content(menus(:sorrentinos).name)

    # Al volver a abrir el filtro, con dos proveedores aplicados, marcar el
    # último vuelve a "Todos".
    open_provider_filter
    expect_row_checked(tuviandita)
    expect_row_checked(office_provider)
    expect_row_unchecked(endulzate)

    tap_row_edge(endulzate)

    expect(page).to have_css("#dashboard-filter-all[aria-checked='true']")
    expect_row_unchecked(tuviandita)
    expect_row_unchecked(office_provider)
    expect_row_unchecked(endulzate)

    click_button "Aplicar"

    within(filter_label) { expect(page).to have_content("Todos") }
    expect(page).to have_content(menus(:milanesa).name)
    expect(page).to have_content(menus(:office_menu).name)
    expect(page).to have_content(menus(:sorrentinos).name)
  end
end
