# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consumer, type: :model do
  fixtures :consumers, :companies, :providers, :benefit_configurations, :benefits, :menus, :schedules

  let(:consumer) { consumers(:one) }
  let(:company_address) { companies(:gogrow).address }

  describe "#delivery_for" do
    it "derives office when the company address is chosen" do
      expect(consumer.delivery_for(providers(:tuviandita), company_address))
        .to eq({ delivery_method: "office", address: company_address })
    end

    it "derives home when another address is chosen and the provider delivers home" do
      expect(consumer.delivery_for(providers(:tuviandita), consumer.address))
        .to eq({ delivery_method: "home", address: consumer.address })
    end

    it "forces office with the company address for an office-only provider" do
      expect(consumer.delivery_for(providers(:office_provider), consumer.address))
        .to eq({ delivery_method: "office", address: company_address })
    end
  end

  describe "#delivery_address_options" do
    fixtures :users

    let(:consumer) do
      Consumer.create!(
        user: User.create!(email: "addresses-#{SecureRandom.hex(4)}@gmail.com", name: "Sofía", password: "password123456"),
        company: companies(:gogrow),
        address: "Ellauri 1234"
      )
    end

    def home_order(address, created_at:)
      menu = Menu.create!(provider: providers(:tuviandita), name: "Milanesa", description: "Plato de prueba", price: 300)
      schedule = Schedule.create!(menu:, date: Date.current + 1, amount: 5)
      Order.create!(consumer:, schedule:, amount: 1, price: 300, address:, delivery_method: :home, created_at:)
    end

    it "lists the office, the profile address and the saved ones, newest first" do
      consumer.saved_addresses.create!(name: "Flora Café", street: "Canelones 892", created_at: 2.days.ago)
      consumer.saved_addresses.create!(name: "La Bicicleta Café", street: "Bv. España 2643", apartment: "Local 2")

      expect(consumer.delivery_address_options.pluck(:label, :address)).to eq([
        [ "Oficina", company_address ],
        [ "Casa", "Ellauri 1234" ],
        [ "La Bicicleta Café", "Bv. España 2643, Local 2" ],
        [ "Flora Café", "Canelones 892" ]
      ])
    end

    it "puts the last custom address an order went to right after the office" do
      flora = consumer.saved_addresses.create!(name: "Flora Café", street: "Canelones 892")
      home_order("Ellauri 1234", created_at: 2.days.ago)
      home_order(flora.full_address, created_at: 1.day.ago)

      expect(consumer.delivery_address_options.pluck(:label).first(2)).to eq([ "Oficina", "Flora Café" ])
    end

    it "keeps a last used address that was not saved" do
      home_order("Colonia 1370, Apto 4", created_at: 1.day.ago)

      expect(consumer.delivery_address_options.second).to include(id: "last_used", address: "Colonia 1370, Apto 4")
    end

    it "does not list another employee's saved addresses" do
      consumers(:other).saved_addresses.create!(name: "Estudio", street: "Colonia 1370")

      expect(consumer.delivery_address_options.pluck(:label)).not_to include("Estudio")
    end
  end

  describe "subsidized meals calculations" do
    before do
      # destroy_all y no delete_all: las órdenes cuelgan de cuentas.
      Order.destroy_all
      Schedule.delete_all
    end

    let(:menu) { menus(:milanesa) }
    let(:today_schedule) { Schedule.create!(menu:, date: Date.current, amount: 30) }

    it "counts orders delivered within the current month" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 3,
        price: 900, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 3

      expect(consumer.reload.monthly_benefit_used_this_month).to eq(3)
      expect(consumer.remaining_monthly_benefit).to eq(17)
    end

    it "does not count cancelled or rejected orders" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 2,
        price: 600, address: consumer.company.address, delivery_method: :office, status: :cancelled
      ).apply_benefit! benefits(:monthly), 1
      Order.create!(
        consumer:, schedule: today_schedule, amount: 1,
        price: 300, address: consumer.company.address, delivery_method: :office, status: :rejected,
        rejection_reason: :out_of_stock
      ).apply_benefit! benefits(:monthly), 1

      expect(consumer.monthly_benefit_used_this_month).to eq(0)
      expect(consumer.remaining_monthly_benefit).to eq(20)
    end

    it "does not count orders delivered in previous or future months" do
      past_schedule = Schedule.create!(menu:, date: 1.month.ago.beginning_of_month, amount: 30)
      future_schedule = Schedule.create!(menu:, date: 1.month.from_now.beginning_of_month, amount: 30)

      Order.create!(
        consumer:, schedule: past_schedule, amount: 5,
        price: 1500, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 5
      Order.create!(
        consumer:, schedule: future_schedule, amount: 4,
        price: 1200, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 4

      expect(consumer.monthly_benefit_used_this_month).to eq(0)
      expect(consumer.remaining_monthly_benefit).to eq(20)
    end

    it "clamps remaining subsidized meals to zero when limit is exceeded" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 25,
        price: 7500, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 20

      expect(consumer.monthly_benefit_used_this_month).to eq(20)
      expect(consumer.remaining_monthly_benefit).to eq(0)
    end
  end

  describe "#benefit_available" do
    it "returns the amount of the active monthly benefit" do
      expect(consumer.monthly_benefit_available).to eq(20)
    end

    it "returns 0 when there is no active monthly benefit" do
      benefits(:monthly).destroy

      expect(consumer.monthly_benefit_available).to eq(0)
    end
  end

  describe "debt and spending" do
    let(:provider) { providers(:tuviandita) }

    # Las cuentas de este bloque se arman a mano con montos exactos, así que
    # tiene que partir sin las que traigan las fixtures.
    before { consumer.accounts.destroy_all }

    it "sums pending accounts for total debt" do
      Account.create!(owner: consumer, provider:, month: 1.month.ago.beginning_of_month, amount: 300)
      Account.create!(owner: consumer, provider:, month: Date.current.beginning_of_month, amount: 450)
      paid_account = Account.create!(owner: consumer, provider:, month: 2.months.ago.beginning_of_month, amount: 200)
      Payment.create!(account: paid_account, status: :approved)

      expect(consumer.total_debt).to eq(750)
    end

    it "sums current month accounts for current_month_spending" do
      Account.create!(owner: consumer, provider:, month: Date.current.beginning_of_month, amount: 450)
      Account.create!(owner: consumer, provider:, month: 1.month.ago.beginning_of_month, amount: 300)

      expect(consumer.current_month_spending).to eq(450)
    end
  end

  describe "#check_debt_alert!" do
    let(:provider) { providers(:tuviandita) }
    let(:alerts) { consumer.user.notifications.where(event: "debt_threshold_exceeded", notifiable: consumer) }

    before { consumer.accounts.destroy_all }

    it "notifies the consumer when the debt exceeds the company threshold" do
      Account.create!(owner: consumer, provider:, amount: 2500)

      consumer.check_debt_alert!

      expect(alerts.active.sole).to have_attributes(
        requires_action: true,
        description: "Tu deuda es de $2.500 y superó el límite de $2.000 definido por RRHH. Regularizá tus pagos para que este aviso desaparezca."
      )
    end

    it "does not notify when the debt equals the threshold" do
      Account.create!(owner: consumer, provider:, amount: 2000)

      consumer.check_debt_alert!

      expect(alerts).to be_empty
    end

    it "uses the threshold set by the company" do
      consumer.company.update!(debt_alert_threshold: 3000)
      Account.create!(owner: consumer, provider:, amount: 2500)

      consumer.check_debt_alert!

      expect(alerts).to be_empty
    end

    it "keeps a single active alert while the debt stays above the threshold" do
      Account.create!(owner: consumer, provider:, amount: 2500)

      consumer.check_debt_alert!
      consumer.check_debt_alert!

      expect(alerts.count).to eq(1)
    end

    it "closes the alert when an approved payment brings the debt back under the threshold" do
      account = Account.create!(owner: consumer, provider:, amount: 2500)
      consumer.check_debt_alert!

      Payment.create!(account:, status: :approved)

      expect(alerts.active).to be_empty
      expect(alerts.closed.count).to eq(1)
    end
  end

  describe "#delivery_addresses" do
    it "returns both consumer and company addresses when both are present" do
      expect(consumer.delivery_addresses).to contain_exactly(consumer.address, consumer.company.address)
    end

    it "omits blank consumer addresses" do
      consumer.update!(address: "")
      expect(consumer.delivery_addresses).to eq([ consumer.company.address ])
    end
  end

  describe "#subsidized_meals_used_this_week" do
    before do
      Order.destroy_all
      Schedule.delete_all
    end

    let(:menu) { menus(:milanesa) }
    let(:today_schedule) { Schedule.create!(menu:, date: Date.current, amount: 30) }

    it "sums active orders delivered in the current week" do
      Order.create!(
        consumer:, schedule: today_schedule, amount: 2,
        price: 600, address: consumer.company.address, delivery_method: :office, status: :confirmed
      ).apply_benefit! benefits(:monthly), 2
      Order.create!(
        consumer:, schedule: today_schedule, amount: 1,
        price: 300, address: consumer.company.address, delivery_method: :office, status: :pending
      ).apply_benefit! benefits(:monthly), 1
      Order.create!(
        consumer:, schedule: today_schedule, amount: 4,
        price: 1200, address: consumer.company.address, delivery_method: :office, status: :cancelled
      ).apply_benefit! benefits(:monthly), 4

      expect(consumer.monthly_benefit_used_this_week).to eq(3)
    end
  end

  describe "#monthly_benefit_for" do
    let(:current_month_schedule) { Schedule.new(date: Date.current) }
    let(:next_month_schedule) { Schedule.new(date: Date.current.next_month.beginning_of_month + 2.days) }

    before do
      consumer.benefits.destroy_all
    end

    it "devuelve el beneficio current para un schedule del mes actual" do
      current_benefit = Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )

      expect(consumer.monthly_benefit_for(current_month_schedule)).to eq(current_benefit)
    end

    it "devuelve el beneficio future más próximo para un schedule del mes siguiente" do
      Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )
      future_benefit = Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :future,
        percentage: 60,
        amount: 15,
        due_date: Date.current.next_month.end_of_month
      )

      expect(consumer.monthly_benefit_for(next_month_schedule)).to eq(future_benefit)
    end

    it "ignora beneficios vencidos (expired) aunque su due_date coincida" do
      Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :expired,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )

      expect(consumer.monthly_benefit_for(current_month_schedule)).to be_nil
    end

    it "no confunde un subsidio especial que vence antes con el beneficio mensual" do
      monthly = Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month + 1.day
      )
      Benefit.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:gift),
        status: :current,
        percentage: 30,
        amount: 2,
        due_date: Date.current
      )

      expect(consumer.monthly_benefit_for(current_month_schedule)).to eq(monthly)
    end

    it "devuelve nil si no existe ningún beneficio válido para la fecha del schedule" do
      expect(consumer.monthly_benefit_for(next_month_schedule)).to be_nil
    end
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id              :bigint           not null, primary key
#  address         :string
#  birthday        :date
#  onboarding_date :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
