# frozen_string_literal: true

require "rails_helper"

# TODO(integración): falta implementar un selector de período antes de poder
# testear que RRHH elija un período y vea sólo ese período. Hoy la pantalla
# lista de golpe todos los períodos pendientes, agrupados por proveedor, y no
# hay ningún control para elegir uno. Historia: IBP-039 "Como RRHH, quiero
# consultar por período cuánto debe GoGrow a cada proveedor y el estado de esos
# pagos para realizar su seguimiento." Criterio 1: "RRHH puede seleccionar un
# período y ver cuánto debe GoGrow a cada proveedor". El resto de la pantalla sí
# está cableado y se prueba más abajo.

# TODO(integración): falta que el pago registre un importe antes de poder testear
# los pagos parciales. La tabla payments no tiene columna de monto: un Payment
# es sólo un estado (pending/submitted/approved/rejected) sobre la cuenta
# entera, así que no hay forma de registrar ni de mostrar que un período se pagó
# en parte. Historia: IBP-039 "consultar por período cuánto debe GoGrow a cada
# proveedor y el estado de esos pagos". Criterio 3: "Se muestran estado,
# vencimiento y pagos parciales o totales cuando existan". El estado, el
# vencimiento y el pago total sí se muestran, y se prueban más abajo.

RSpec.describe "Consultar por período la deuda de GoGrow con cada proveedor" do
  fixtures :users, :admins, :companies, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments

  # La cuenta de la empresa con el período actual: el subsidio de los tres
  # pedidos confirmados de orders.yml (300.50 + 150.25 + 150.25).
  let(:current_period) { accounts(:gogrow_tuviandita_current) }
  # El período anterior, con el comprobante aprobado: el del historial.
  let(:settled_period) { accounts(:gogrow_tuviandita_previous) }

  # Cada request de este repo tarda varios segundos en el entorno de desarrollo
  # (repo montado desde Windows + middleware de Vite), bastante más que los dos
  # segundos por defecto. Los matchers de Capybara reintentan solos, así que
  # alcanza con esperarlos más: no hace falta ningún sleep.
  around do |example|
    Capybara.default_max_wait_time = 30
    example.run
  end

  after { Capybara.default_max_wait_time = 2 }

  def money(amount)
    whole, cents = format("%.2f", amount).split(".")
    "#{whole.reverse.scan(/\d{1,3}/).join('.').reverse},#{cents} UYU"
  end

  def month_label(date)
    I18n.l(date, format: :month_year)
  end

  def due_label(period)
    I18n.t("pages.admin.payments.index.due", date: period.due_date.strftime("%d/%m/%y"))
  end

  def sign_in_as_hr
    sign_in users(:admin), role: :admin
    visit admin_payments_path
  end

  # El detalle del período se pide por fetch y se pinta en un panel lateral, así
  # que hay que esperar a que llegue la tabla, no sólo a que abra el panel.
  def open_detail_of_the_period
    click_on "Ver detalle"
    expect(page).to have_selector("tbody tr", minimum: 1)
  end

  # Un segundo período pendiente, de otro proveedor y de otro mes. Se crea a
  # pedido porque los únicos ejemplos que necesitan más de un concepto para
  # sumar son los que deben ver dos tarjetas de período en la misma pantalla.
  def add_older_period
    Account.create!(
      owner: companies(:gogrow),
      provider: providers(:endulzate),
      month: 2.months.ago.beginning_of_month,
      amount: 250.0
    )
  end

  describe "criterio 1: la deuda con cada proveedor, período por período" do
    it "lists every provider and owes only what the company itself still owes" do
      sign_in_as_hr

      expect(page).to have_content("Provider User")
      expect(page).to have_content("Other Provider User")
      expect(page).to have_content("Office Provider User")

      expect(page).to have_content(money(current_period.amount))
      expect(page).to have_content(month_label(current_period.month))

      # Las cuentas de los empleados son suyas: la parte de la vianda la pagan
      # ellos, no la empresa.
      expect(page).to have_no_content(money(accounts(:one_tuviandita_current).amount))
      expect(page).to have_no_content(money(accounts(:other_tuviandita_current).amount))
      expect(page).to have_no_content(money(accounts(:one_endulzate_current).amount))
    end

    it "tells the company that a provider it has no pending debt with owes nothing" do
      sign_in_as_hr

      expect(page).to have_content("Office Provider User")
      expect(page).to have_content("¡Sin deudas pendientes con este proveedor!")
    end

    it "shows an unpaid period in the pending tab and the settled one in the history" do
      sign_in_as_hr

      expect(page).to have_content(month_label(current_period.month))
      expect(page).to have_no_content(month_label(settled_period.month))

      click_on "Historial"

      expect(page).to have_content("Provider User: #{month_label(settled_period.month)}")
      expect(page).to have_no_content(month_label(current_period.month))
    end
  end

  describe "criterio 2: el desglose del período" do
    it "opens the confirmed orders that make up the balance of the period" do
      sign_in_as_hr

      open_detail_of_the_period

      expect(page).to have_selector("tbody tr", count: 3)
      # La tabla recorta el nombre del plato a veinte caracteres.
      expect(page).to have_content("Milanesa con papas f...", count: 3)
    end

    it "closes the breakdown with the total of the period it belongs to" do
      sign_in_as_hr

      open_detail_of_the_period

      # Dentro del panel los importes van sin formatear, así que se compara
      # contra el número pelado. Que las filas sumen ese total es otro tema:
      # ver DEFECT-detalle-total-no-coincide-30-09-2026.md.
      within(:css, "[role='dialog']") do
        expect(page).to have_content(current_period.amount.to_i.to_s)
      end
    end
  end

  describe "criterio 3: estado, vencimiento y pagos" do
    it "shows a period nobody paid as pending, with the day it falls due" do
      sign_in_as_hr

      within(:css, "[data-status='pending']") { expect(page).to have_content("Pendiente") }
      expect(page).to have_content(due_label(current_period))
    end

    it "keeps showing the due day once the period is overdue" do
      # El vencimiento es el quinto día del mes siguiente; al día siguiente ya venció.
      travel_to(current_period.due_date + 1.day) { sign_in_as_hr }

      expect(page).to have_content(due_label(current_period))
    end

    it "keeps a period whose receipt was only submitted in the pending tab" do
      submit_receipt_for(current_period)

      sign_in_as_hr

      within(:css, "[data-status='submitted']") { expect(page).to have_content("Por revisar") }
      expect(page).to have_content(money(current_period.amount))
      # Informado no es confirmado: el período sigue debiéndose y con vencimiento.
      expect(page).to have_content(due_label(current_period))
    end

    it "moves a period paid in full to the history and drops its due day" do
      sign_in_as_hr

      click_on "Historial"

      within(:css, "[data-status='approved']") { expect(page).to have_content("Confirmado") }
      expect(page).to have_content(money(settled_period.amount))
      expect(page).to have_no_content("Vence:")
    end
  end

  describe "criterio 4: los totales coinciden con la suma de los conceptos" do
    it "adds up every pending period into a single total debt figure" do
      older_period = add_older_period
      periods = [ current_period, older_period ]

      sign_in_as_hr

      periods.each do |period|
        expect(page).to have_content(money(period.amount))
        expect(page).to have_content(month_label(period.month))
      end

      expect(page).to have_content(money(periods.sum { it.amount.to_f }))
    end

    it "leaves a settled period out of the total it still owes" do
      older_period = add_older_period
      owed = [ current_period, older_period ].sum { it.amount.to_f }

      sign_in_as_hr

      expect(page).to have_content(money(owed))
      expect(page).to have_no_content(money(owed + settled_period.amount.to_f))
    end
  end

  describe "permisos y privacidad" do
    it "turns away a visitor with no session" do
      visit admin_payments_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "turns away a role that is not HR" do
      sign_in users(:one), role: :consumer

      visit admin_payments_path

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_no_content(money(current_period.amount))
    end
  end

  describe "persistencia y consistencia entre vistas" do
    it "owes the same after signing out and in again" do
      owed = [ current_period, add_older_period ].sum { it.amount.to_f }

      sign_in_as_hr
      expect(page).to have_content(money(owed))
      sign_out

      sign_in users(:admin), role: :admin
      visit admin_payments_path

      expect(page).to have_content(money(owed))
    end

    it "owes the provider the same amount the provider is collecting" do
      sign_in_as_hr
      expect(page).to have_content(money(current_period.amount))
      sign_out

      sign_in users(:provider_user), role: :provider
      visit provider_collections_path

      # La cuenta de la empresa dentro del grupo de GoGrow. El find va por xpath
      # porque el texto del botón es el grupo entero ("Empresa" + estado + importe)
      # y Capybara no acepta un Regexp para buscar botones.
      company_row = find(:xpath, "//button[contains(normalize-space(string(.)), 'Empresa')]")

      within(company_row) do
        expect(page).to have_content(money(current_period.amount))
        expect(page).to have_css("[data-status='pending']")
      end
    end
  end

  # Un comprobante informado deja el período en "por revisar", que no es lo mismo
  # que pagado. El modelo exige el adjunto, así que se sube uno de verdad.
  def submit_receipt_for(period)
    payment = Payment.new(account: period, provider: period.provider, status: :submitted)
    payment.receipt.attach(
      io: StringIO.new("%PDF-1.4 comprobante"),
      filename: "comprobante.pdf",
      content_type: "application/pdf"
    )
    payment.save!
  end
end
