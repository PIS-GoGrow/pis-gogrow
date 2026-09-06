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

company = Company.create! name: "GoGrow", address: "18 de Julio 1006"
consumer = Consumer.create! username: "Juan Andrés", company: company, email: "a@a.com", address: "Julio Herrera y Reissig 565"
provider = Provider.create! username: "TuViandita", order_deadline: Time.now + 3.hours
menu = Menu.create! provider: provider, name: "Milanesa con papas fritas", price: 300, description: ""
schedule = Schedule.create! menu: menu, date: Date.today, amount: 7
order = Order.create! consumer: consumer, schedule: schedule, price: 300, discounted_price: 0, amount: 1
account = Account.create! amount: 300, month: Date.today, owner: consumer
account.orders << order
Payment.create! account: account

notification_config = NotificationConfiguration.create! description: "Notificaciones de orden en camino"
notification_config.consumers << consumer
