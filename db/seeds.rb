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
