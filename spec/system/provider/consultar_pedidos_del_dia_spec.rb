# frozen_string_literal: true

# Historia IBP-055 (US-P10): "Como proveedor, quiero consultar los pedidos del
# día y su estado, para organizar la preparación y entrega."

require "rails_helper"

RSpec.describe "Consultar los pedidos del día", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:provider_user) { users(:provider_user) }
  let(:today) { Date.current }
  let(:future_day) { Date.current + 3 }

  def day_label(date)
    "Día: #{date.strftime('%d/%m')}"
  end

  def open_day?(date)
    page.has_css?("button[aria-expanded='true']", text: day_label(date))
  end

  before do
    page.current_window.resize_to(1400, 1400)
    sign_in provider_user, role: :provider
    visit provider_orders_path
  end

  # CA1: el día actual es el valor inicial.
  it "arranca en el día actual con sus pedidos" do
    expect(page).to have_css("button[aria-expanded='true']", text: day_label(today))
    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_content("Enviar a: Julio Herrera y Reissig 565 (Casa)")
    expect(page).to have_no_content("Enviar a: 18 de Julio 1006 (Oficina)")
  end

  it "resume las viandas y el monto de cada día" do
    expect(page).to have_css("button", text: "#{day_label(today)} | Viandas: 1 | Monto: $300,50")
    expect(page).to have_css("button", text: "#{day_label(future_day)} | Viandas: 6 | Monto: $1.803")
  end

  # CA1: se puede consultar otra fecha.
  it "permite consultar los pedidos de otro día" do
    click_button day_label(future_day)

    expect(page).to have_css("button[aria-expanded='true']", text: day_label(future_day))
    expect(page).to have_content("Enviar a: 18 de Julio 1006 (Oficina)")
    expect(page).to have_css("button[aria-expanded='false']", text: day_label(today))
  end

  it "muestra los pedidos anteriores en el historial" do
    click_on "Historial"

    expect(page).to have_css("button[aria-expanded='true']", text: day_label(today - 5))
    expect(page).to have_no_css("button", text: day_label(today))
  end

  # CA2: identificación, plato, cantidad, modalidad y estado.
  it "muestra de cada pedido su identificación, plato, cantidad, modalidad y estado" do
    order = orders(:upcoming_pending_today)

    within("[data-slot='card']", text: "PED-#{order.id}") do
      expect(page).to have_content("Test User - GoGrow")
      expect(page).to have_content("Milanesa con papas fritas")
      expect(page).to have_content("x1")
      expect(page).to have_content("(Casa)")
      expect(page).to have_content("Por revisar")
    end
  end

  it "deja los botones visibles: confirmar solo si está por revisar y rechazar también si está confirmado" do
    expect(page).to have_button("Confirmar", disabled: false, count: 1)
    expect(page).to have_button("Rechazar", disabled: false, count: 1)

    click_button day_label(future_day)

    expect(page).to have_button("Confirmar", disabled: true, minimum: 1)
    expect(page).to have_button("Confirmar", disabled: false, count: 1)
    confirmed_card = find("[data-slot='card']", text: "Confirmado", match: :first)
    expect(confirmed_card).to have_button("Rechazar", disabled: false)
    expect(confirmed_card).to have_button("Confirmar", disabled: true)
    cancelled_card = find("[data-slot='card']", text: "Cancelado")
    expect(cancelled_card).to have_button("Rechazar", disabled: true)
  end

  # CA3: filtros por estado y otros criterios operativos.
  describe "filtros" do
    it "filtra por estado" do
      click_on "Confirmados"

      expect(page).to have_no_css("button", text: day_label(today))
      expect(page).to have_css("button[aria-expanded='true']", text: day_label(future_day))
      expect(page).to have_css("[data-status='confirmed']")
      expect(page).to have_no_css("[data-status='pending'], [data-status='cancelled'], [data-status='rejected']")

      click_on "Por revisar"

      expect(page).to have_css("button", text: day_label(today))
      expect(page).to have_css("[data-status='pending']")
      expect(page).to have_no_css("[data-status='confirmed']")

      click_on "Todos"

      click_button day_label(future_day)

      expect(page).to have_css("[data-status='confirmed']")
      expect(page).to have_css("[data-status='cancelled']")
      expect(page).to have_css("[data-status='rejected']")
    end

    it "filtra por tipo de entrega" do
      click_button "Filtrar por tipo de entrega"
      find("label", text: "Oficina GoGrow").click
      click_button "Aplicar"

      expect(page).to have_content("Entregas: Oficina GoGrow")
      expect(page).to have_no_css("button", text: day_label(today))
      expect(page).to have_content("(Oficina)")
      expect(page).to have_no_content("(Casa)")
    end

    it "busca por consumidor, plato, dirección o código" do
      fill_in "Buscar pedido, plato, consumidor...", with: "artigas"

      expect(page).to have_css("button", text: day_label(future_day))
      expect(page).to have_content("Enviar a: Bulevar Artigas 1234")
      expect(page).to have_no_css("button", text: day_label(today))

      fill_in "Buscar pedido, plato, consumidor...", with: "ped-#{orders(:upcoming_pending_today).id}"

      expect(page).to have_css("button", text: day_label(today))
      expect(page).to have_no_content("Bulevar Artigas 1234")
    end

    it "avisa cuando ningún pedido coincide" do
      fill_in "Buscar pedido, plato, consumidor...", with: "zzz"

      expect(page).to have_content("No tenés pedidos que coincidan con los filtros.")
    end
  end

  # CA4: solo las órdenes del proveedor autenticado.
  it "no muestra los pedidos de otro proveedor" do
    other_menu = menus(:sorrentinos)
    Order.create!(
      consumer: consumers(:other),
      schedule: schedules(:sorrentinos_today),
      status: :pending,
      delivery_method: :office,
      amount: 1,
      price: 320.00,
      discounted_price: 160.00,
      selected_options: selection_for(other_menu)
    )

    visit provider_orders_path

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_no_content(other_menu.name)
  end

  describe "en una pantalla de escritorio" do
    it "muestra la lista de días a la izquierda y los pedidos del día elegido a la derecha" do
      expect(open_day?(today)).to be(true)

      layout = page.evaluate_script(<<~JS)
        (() => {
          const trigger = document.querySelector("[data-slot='collapsible-trigger']").getBoundingClientRect()
          const content = document.querySelector("[data-slot='collapsible-content']").getBoundingClientRect()
          return { contentIsBeside: content.left >= trigger.right, contentStartsAtTop: Math.abs(content.top - trigger.top) < 2 }
        })()
      JS

      expect(layout).to eq("contentIsBeside" => true, "contentStartsAtTop" => true)
    end

    it "no cierra el día elegido al tocarlo" do
      click_button day_label(today)

      expect(page).to have_css("button[aria-expanded='true']", text: day_label(today))
    end
  end

  describe "en un celular" do
    before do
      page.current_window.resize_to(390, 844)
      visit provider_orders_path
    end

    it "muestra los días como un acordeón con la barra de navegación inferior" do
      expect(page).to have_css("nav[aria-label='Navegación del proveedor']")
      expect(open_day?(today)).to be(true)

      layout = page.evaluate_script(<<~JS)
        (() => {
          const trigger = document.querySelector("[data-slot='collapsible-trigger']").getBoundingClientRect()
          const content = document.querySelector("[data-slot='collapsible-content']").getBoundingClientRect()
          return { contentIsBelow: content.top >= trigger.bottom }
        })()
      JS

      expect(layout).to eq("contentIsBelow" => true)
    end

    it "cierra el día abierto al tocarlo y abre otro" do
      click_button day_label(today)

      expect(page).to have_css("button[aria-expanded='false']", text: day_label(today))

      click_button day_label(future_day)

      expect(page).to have_css("button[aria-expanded='true']", text: day_label(future_day))
    end
  end
end
