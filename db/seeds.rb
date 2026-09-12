# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

date = Date.today

company = Company.create! name: "GoGrow", address: "18 de Julio 1006"

provider_user = User.create! email: "pis2026.tuviandita@gmail.com", name: "TuViandita", password_digest: "$2a$12$bJmXACYR/Ob7pRPwQQ90BeTxYrZ8zRuUkJc8rBM/zaWcKY0wsxmku", verified: true, google_uid: "108316160859916934526", avatar_url: "https://lh3.googleusercontent.com/a/ACg8ocJI-3dIr052h53KVJC3tMso4PDVJV_TwqQT4IQigdM72LNlKw"
provider = Provider.create! order_deadline: Time.now + 3.hours, user: provider_user

menu = Menu.create! provider: provider, name: "Milanesa con papas fritas", price: 300, description: "Opción de carne o pollo"
schedule = Schedule.create! menu:, date: date, amount: 7
Review.create! description: "Muy buena!", rating: 5, menu: menu

menu2 = Menu.create! provider: provider, name: "Empanadas de carne", price: 500, description: "Docena de empanadas caseras"
schedule2 = Schedule.create! menu: menu2, date: date + 1.day, amount: 10

menu3 = Menu.create! provider: provider, name: "Ensalada César con pollo", price: 250, description: "Con aderezo casero y crutones"
schedule3 = Schedule.create! menu: menu3, date: date + 2.days, amount: 5

past_schedule = Schedule.create! menu:, date: date - 7.days, amount: 7
recent_past_schedule = Schedule.create! menu: menu2, date: date - 2.days, amount: 10

consumer_user = User.create! email: "usuariopruebapis@gmail.com", name: "TuViandita", google_uid: "111721831687592318354", password_digest: "$2a$12$w4gRBetBMUY0nAyf0T3aU.Vzpk/.Wu75sHOcs3aGX4k.gF7qsG3/q", avatar_url: "https://lh3.googleusercontent.com/a/ACg8ocKtGT92NBBhunNX_WpKMt3SLxIf-dmL8soi3s0Bnwlrxn_Jig", verified: true
consumer = Consumer.create! company:, address: "Julio Herrera y Reissig 565", user: consumer_user
Benefit.create! consumer:, amount: 20, description: "Viandas mensuales", percentage: 50, due_date: date + 1.month

# Cubren las dos secciones de "Mis pedidos": pendientes/próximos e historial,
# incluida la orden sin schedule que deja el dependent: :nullify.
order = Order.create! consumer:, schedule:, status: :pending, price: 300.50, discounted_price: 150.25, amount: 1
Order.create! consumer:, schedule: schedule2, status: :confirmed, price: 601.00, discounted_price: 300.50, amount: 2
Order.create! consumer:, schedule: schedule3, status: :pending, price: 250.00, discounted_price: 125.00, amount: 1
Order.create! consumer:, schedule: schedule3, status: :cancelled, price: 250.00, discounted_price: 125.00, amount: 1
Order.create! consumer:, schedule: past_schedule, status: :confirmed, price: 300.50, discounted_price: 150.25, amount: 1
Order.create! consumer:, schedule: recent_past_schedule, status: :rejected, price: 500.00, discounted_price: 250.00, amount: 1
Order.new(consumer:, status: :confirmed, price: 300.50, discounted_price: 150.25, amount: 1).save! validate: false

account = Account.create! amount: 300, month: date, owner: consumer
account.orders << order
Payment.create! account: account

admin_user = User.create! avatar_url: "https://lh3.googleusercontent.com/a/ACg8ocIQbkCUs7...", email: "rrhh.gogrow@gmail.com", google_uid: "101425658623552684238", name: "Juan Admin", password_digest: "$2a$12$kDAZOZpncJzrsfYTgpE.Xu47ZCiUJWL/a4TI5WcI0Q1LeecxlSsMe", verified: true
amin = Admin.create! user: admin_user, company: company

notification_config = NotificationConfiguration.create! description: "Notificaciones de orden en camino"
notification_config.consumers << consumer
