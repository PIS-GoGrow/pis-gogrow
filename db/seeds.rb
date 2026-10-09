# frozen_string_literal: true

# Para agregar cuentas de meses pasados
# Por como funciona la creacion de accounts solo se crean para el mes actual, por lo que si se quiere agregar cuentas de meses pasados hay que hacerlo manualmente
# Con esto le podes hacer creer al sistema que esta en un mes anterior
require "active_support/testing/time_helpers"
include ActiveSupport::Testing::TimeHelpers

week_start = Date.current.beginning_of_week(:monday)

company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")

tu_viandita_user = User.create!(
  email: "pis2026.tuviandita@gmail.com",
  name: "TuViandita",
  password_digest: "$2a$12$bJmXACYR/Ob7pRPwQQ90BeTxYrZ8zRuUkJc8rBM/zaWcKY0wsxmku",
  verified: true,
  google_uid: "108316160859916934526"
)
tu_viandita = Provider.create!(
  order_deadline: Time.current + 3.hours,
  home_delivery: true,
  user: tu_viandita_user
)

endulzate_user = User.create!(
  email: "endulzate.by.noe@gmail.com",
  name: "Endulzate by Noe",
  password_digest: "$2a$12$bJmXACYR/Ob7pRPwQQ90BeTxYrZ8zRuUkJc8rBM/zaWcKY0wsxmku",
  verified: true,
  google_uid: "109316160859916934526"
)
endulzate = Provider.create!(
  order_deadline: Time.current + 3.hours,
  home_delivery: false,
  user: endulzate_user
)

menus = [
  {
    provider: tu_viandita,
    name: "Milanesa con papas fritas",
    description: "Opción de carne o pollo",
    price: 300,
    option_groups_attributes: [
      { name: "Salsas", limit: 1, options: [ "Mayonesa de ajo", "Ketchup" ] }
    ],
    day: 0,
    amount: 7
  },
  {
    provider: tu_viandita,
    name: "Empanadas de carne",
    description: "Docena de empanadas caseras",
    price: 500,
    day: 1,
    amount: 10
  },
  {
    provider: tu_viandita,
    name: "Ensalada César con pollo",
    description: "Con aderezo casero y crutones",
    price: 250,
    day: 2,
    amount: 5
  },
  {
    provider: tu_viandita,
    name: "Ravioles con salsa de tomate",
    description: "Pasta fresca con salsa a elección",
    price: 320,
    option_groups_attributes: [
      { name: "Salsas", limit: 1, options: [ "Filetto", "Bolognesa" ] }
    ],
    day: 3,
    amount: 8
  },
  {
    provider: tu_viandita,
    name: "Bowl de lentejas y vegetales",
    description: "Opción vegetariana completa",
    price: 280,
    day: 4,
    amount: 6
  },
  {
    provider: endulzate,
    name: "Sorrentinos de ricota",
    description: "Pasta rellena con opciones a elección",
    price: 300,
    option_groups_attributes: [
      { name: "Rellenos", limit: 1, options: [ "Ricota y nuez", "Ricota y espinaca" ] },
      { name: "Salsas", limit: 1, options: [ "Filetto", "Bolognesa", "Rosa" ] }
    ],
    day: 0,
    amount: 8
  },
  {
    provider: endulzate,
    name: "Wok de verduras con arroz",
    description: "Vegetales salteados y arroz integral",
    price: 280,
    day: 2,
    amount: 7
  },
  {
    provider: endulzate,
    name: "Tarta de jamón y queso",
    description: "Tarta casera acompañada de ensalada",
    price: 300,
    day: 4,
    amount: 6
  }
]

menus.each do |attributes|
  day = attributes.delete(:day)
  amount = attributes.delete(:amount)
  menu = Menu.create!(**attributes)
  Schedule.create!(menu:, date: week_start + day.days, amount:)
end

Review.create!(
  description: "Muy buena opción para el almuerzo.",
  rating: 5,
  menu: tu_viandita.menus.find_by!(name: "Milanesa con papas fritas")
)

consumer_user = User.create!(
  email: "usuariopruebapis@gmail.com",
  name: "Juan Pérez",
  password_digest: "$2a$12$w4gRBetBMUY0nAyf0T3aU.Vzpk/.Wu75sHOcs3aGX4k.gF7qsG3/q",
  verified: true,
  google_uid: "111721831687592318354"
)
consumer = Consumer.create!(
  company:,
  address: "Julio Herrera y Reissig 565",
  user: consumer_user,
  birthday: Date.new(1994, 7, 14),
  onboarding_date: Date.new(2023, 3, 1)
)

admin_user = User.create!(
  email: "rrhh.gogrow@gmail.com",
  name: "Juan Admin",
  password_digest: "$2a$12$kDAZOZpncJzrsfYTgpE.Xu47ZCiUJWL/a4TI5WcI0Q1LeecxlSsMe",
  verified: true,
  google_uid: "101425658623552684238"
)
admin = Admin.create!(user: admin_user, company:)

benefit_config = BenefitConfiguration.create! subsidy_percentage: 50, name: "Subsidio base", company:, created_by: admin_user
benefit_config.benefit_rules.create! max_price: 500, limit: 20, effective_from: Date.current, type: MonthlyBenefit.name

consumer.saved_addresses.create!(name: "Flora Café", street: "Canelones 892")
consumer.saved_addresses.create!(name: "La Bicicleta Café", street: "Bv. España 2643", apartment: "Local 2")

benefit = Benefit.create!(
  consumer:,
  amount: 20,
  description: "Viandas mensuales",
  percentage: 50,
  benefit_configuration: benefit_config,
  due_date: Date.current.end_of_month
)

# Cubren las dos secciones de "Mis pedidos": pendientes/próximos e historial,
# incluida la orden sin schedule que deja el dependent: :nullify.
past_schedule = Schedule.create!(
  menu: Menu.first,
  date: week_start - 7.days,
  amount: 7
)

# Un pedido de un plato con opciones necesita la elección del empleado, así que
# los de ejemplo toman la primera de cada grupo.
def default_selection_for(menu)
  menu.option_groups.map do |group|
    { group_id: group.id, name: group.name, values: [ group.options.first ] }
  end
end

upcoming_schedules = Schedule.where("date >= ?", Date.current).order(:date)
if (first_schedule = upcoming_schedules.first)
  order = Order.create!(
    consumer:,
    schedule: first_schedule,
    status: :pending,
    price: first_schedule.menu.price,
    discounted_price: first_schedule.menu.price / 2,
    amount: 1,
    address: company.address,
    delivery_method: :office,
    selected_options: default_selection_for(first_schedule.menu)
  )
  order.apply_benefit! benefit, 1
end

# Una orden confirmada por proveedor genera las cuentas que aparecen en Pagos
# pendientes. El Payment se crea recién cuando el empleado sube el comprobante.
[ tu_viandita, endulzate ].each do |provider|
  schedule = Schedule.joins(:menu)
                     .where(menus: { provider_id: provider.id })
                     .order(date: :desc)
                     .first
  next unless schedule

  order = Order.create!(
    consumer:,
    schedule:,
    status: :confirmed,
    price: schedule.menu.price,
    discounted_price: schedule.menu.price / 2,
    amount: 1,
    address: company.address,
    delivery_method: :office,
    selected_options: default_selection_for(schedule.menu)
  )
  order.apply_benefit! benefit, 1
end

order = Order.create!(
  consumer:,
  schedule: past_schedule,
  status: :confirmed,
  price: 300.50,
  discounted_price: 150.25,
  amount: 1,
  address: company.address,
  delivery_method: :office,
  selected_options: default_selection_for(past_schedule.menu)
)
order.apply_benefit! benefit, 1


# Cuentas pendientes de pago de meses anteriores (para probar el historial de pagos)
[
  { provider: tu_viandita, months_ago: 2 },
  { provider: tu_viandita, months_ago: 3 }
].each do |data|
  provider = data[:provider]
  menu = provider.menus.first

  travel_to(data[:months_ago].months.ago.beginning_of_month + 3.days) do
    schedule = Schedule.create!(
      menu:,
      date: Date.current,
      amount: 5
    )

    Order.create!(
      consumer:,
      schedule:,
      status: :confirmed,
      price: menu.price,
      discounted_price: menu.price / 2,
      amount: 1,
      address: company.address,
      delivery_method: :office,
      selected_options: default_selection_for(menu)
    )
  end
end

# Order.new(consumer:, status: :confirmed, price: 300.50, discounted_price: 150.25, amount: 1).save!(validate: false)

# Cobros del proveedor en distintos estados, para que la pantalla no se vea
# toda pendiente. Las cuentas ya las crearon los pedidos de más arriba.
def seed_payment(account, status)
  # El modelo exige rejection_reason cuando el estado es rejected.
  rejection_reason = "Comprobante ilegible, subí uno nuevo." if status == :rejected

  payment = Payment.new(account:, provider: account.provider, status:, rejection_reason:)
  payment.receipt.attach(
    io: Rails.root.join("public/icon.png").open,
    filename: "comprobante.png",
    content_type: "image/png"
  )
  payment.save!
end

# TuViandita queda con los cuatro estados repartidos en las dos pestañas:
# - este mes (cuentas reales de los pedidos): el empleado informó su pago y la
#   empresa todavía no, así que va a Pendientes;
# - hace dos meses: la empresa pagó pero al empleado le rechazaron el
#   comprobante, así que sigue en Pendientes;
# - el mes pasado: todo confirmado, así que va al Historial.
seed_payment(consumer.accounts.find_by!(provider: tu_viandita, month: Date.current.beginning_of_month), :submitted)

{ 2.months.ago => [ :approved, :rejected ], 1.month.ago => [ :approved, :approved ] }.each do |date, (company_status, consumer_status)|
  month = date.beginning_of_month

  # find_or_create_by!, no create!: el mes "hace 2 meses" ya tiene cuenta de
  # empresa y de empleado creadas por ensure_accounts! (las Order de más
  # arriba), así que un create! directo pisaría el índice único. Se fuerza el
  # amount para esta demo sin importar si la cuenta ya existía.
  company_account = company.accounts.find_or_create_by!(provider: tu_viandita, month:)
  company_account.update!(amount: 1_250.00)
  seed_payment(company_account, company_status)

  consumer_account = consumer.accounts.find_or_create_by!(provider: tu_viandita, month:)
  consumer_account.update!(amount: 1_250.00)
  seed_payment(consumer_account, consumer_status)
end

# Un PDF de una página armado a mano: el proyecto no tiene librería de PDF y
# para las seeds alcanza con que el archivo abra y se lea como una factura.
# Las cadenas van en Latin-1, que es lo que entiende WinAnsiEncoding.
def invoice_pdf(lines)
  content = lines.each_with_index.map do |line, index|
    text = line.encode("ISO-8859-1", invalid: :replace, undef: :replace, replace: "?").gsub(/[\\()]/) { "\\#{it}" }
    "BT /F1 #{index.zero? ? 18 : 12} Tf 64 #{740 - index * 28} Td (#{text}) Tj ET"
  end.join("\n")

  objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
    "<< /Length #{content.bytesize} >>\nstream\n#{content}\nendstream",
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"
  ]

  pdf = +"%PDF-1.4\n"
  offsets = objects.each_with_index.map do |object, index|
    offset = pdf.bytesize
    pdf << "#{index + 1} 0 obj\n#{object}\nendobj\n"
    offset
  end

  xref_offset = pdf.bytesize
  pdf << "xref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
  offsets.each { pdf << format("%010d 00000 n \n", it) }
  pdf << "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref_offset}\n%%EOF\n"

  StringIO.new(pdf.force_encoding(Encoding::BINARY))
end

# Facturas de TuViandita a GoGrow: el mes pasado aprobada (se descarga desde el
# Historial), hace dos meses por revisar y este mes todavía sin subir.
{ 1.month.ago => :approved, 2.months.ago => :pending }.each do |date, status|
  account = company.accounts.find_by!(provider: tu_viandita, month: date.beginning_of_month)
  period = I18n.l(account.month, format: "%B %Y")
  invoice = account.invoices.build(issued_on: account.month.end_of_month, total_amount: account.amount, status:)
  invoice.file.attach(
    io: invoice_pdf([
      "TuViandita",
      "Factura a #{company.name} - #{company.address}",
      "Periodo: #{period}",
      "Fecha de emision: #{I18n.l(account.month.end_of_month, format: "%d/%m/%Y")}",
      "Total: $ #{account.amount.to_i}"
    ]),
    filename: "factura-#{account.month.strftime("%Y-%m")}.pdf",
    content_type: "application/pdf"
  )
  invoice.save!
end

# Cargar las configuraciones de notificación a la app
Rake::Task["notifications:sync"].invoke
