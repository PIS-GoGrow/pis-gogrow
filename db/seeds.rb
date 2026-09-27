# frozen_string_literal: true

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
    sauces: [ "Mayonesa de ajo", "Ketchup" ],
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
    sauces: [ "Filetto", "Bolognesa" ],
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
    fillings: [ "Ricota y nuez", "Ricota y espinaca" ],
    sauces: [ "Filetto", "Bolognesa", "Rosa" ],
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
  user: consumer_user
)
Benefit.create!(
  consumer:,
  amount: 20,
  description: "Viandas mensuales",
  percentage: 50,
  due_date: week_start + 1.month
)

# Cubren las dos secciones de "Mis pedidos": pendientes/próximos e historial,
# incluida la orden sin schedule que deja el dependent: :nullify.
past_schedule = Schedule.create!(
  menu: Menu.first,
  date: week_start - 7.days,
  amount: 7
)

upcoming_schedules = Schedule.where("date >= ?", Date.current).order(:date)
if (first_schedule = upcoming_schedules.first)
  Order.create!(
    consumer:,
    schedule: first_schedule,
    status: :pending,
    price: first_schedule.menu.price,
    discounted_price: first_schedule.menu.price / 2,
    amount: 1,
    address: company.address,
    delivery_method: :office
  )
end

# Una orden confirmada por proveedor genera las cuentas que aparecen en Pagos
# pendientes. El Payment se crea recién cuando el empleado sube el comprobante.
[ tu_viandita, endulzate ].each do |provider|
  schedule = Schedule.joins(:menu)
                     .where(menus: { provider_id: provider.id })
                     .order(date: :desc)
                     .first
  next unless schedule

  Order.create!(
    consumer:,
    schedule:,
    status: :confirmed,
    price: schedule.menu.price,
    discounted_price: schedule.menu.price / 2,
    amount: 1,
    address: company.address,
    delivery_method: :office
  )
end

Order.create!(
  consumer:,
  schedule: past_schedule,
  status: :confirmed,
  price: 300.50,
  discounted_price: 150.25,
  amount: 1,
  address: company.address,
  delivery_method: :office
)

# Order.new(consumer:, status: :confirmed, price: 300.50, discounted_price: 150.25, amount: 1).save!(validate: false)

admin_user = User.create!(
  email: "rrhh.gogrow@gmail.com",
  name: "Juan Admin",
  password_digest: "$2a$12$kDAZOZpncJzrsfYTgpE.Xu47ZCiUJWL/a4TI5WcI0Q1LeecxlSsMe",
  verified: true,
  google_uid: "101425658623552684238"
)
Admin.create!(user: admin_user, company:)

notification_configuration = NotificationConfiguration.create!(
  description: "Notificaciones de orden en camino"
)
notification_configuration.consumers << consumer

# Cobros del proveedor en distintos estados, para que la pantalla no se vea
# toda pendiente. Las cuentas ya las crearon los pedidos de más arriba.
def seed_payment(account, status)
  payment = Payment.new(account:, provider: account.provider, status:)
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
  seed_payment(company.accounts.create!(provider: tu_viandita, month:, amount: 1_250.00), company_status)
  seed_payment(consumer.accounts.create!(provider: tu_viandita, month:, amount: 1_250.00), consumer_status)
end
