# frozen_string_literal: true

class AdminConsumerSummary
  # Estado que resume varias cuentas del mismo mes: el que más atención pide.
  STATUS_PRIORITY = %w[pending rejected submitted approved].freeze

  ConsumerRow = Data.define(:consumer, :amount, :status) do
    delegate :id, to: :consumer

    def name = consumer.user.name

    def email = consumer.user.email
  end

  ProviderRow = Data.define(:name, :amount, :status)

  MonthRow = Data.define(:month, :accounts) do
    def key = month.strftime("%Y-%m")

    def year = month.year

    def amount = AdminConsumerSummary.amount_of(accounts)

    def status = AdminConsumerSummary.status_of(accounts)

    def orders
      accounts.flat_map { it.orders.select(&:confirmed?) }.sort_by(&:created_at)
    end

    def subsidy = orders.sum { it.subsidy || 0 }.to_f

    def providers
      accounts
        .map { ProviderRow.new(name: it.provider.user.name, amount: it.amount.to_f, status: it.collection_status) }
        .sort_by(&:name)
    end
  end

  def self.amount_of(accounts) = accounts.sum { it.amount || 0 }.to_f

  # nil cuando no hay nada que cobrar: la pantalla lo muestra como "Sin consumos".
  def self.status_of(accounts)
    statuses = accounts.select { it.amount.to_d.positive? }.map(&:collection_status)
    return if statuses.empty?

    STATUS_PRIORITY.find { it.in?(statuses) }
  end

  def self.rows_for(company)
    consumers = company.consumers.joins(:user).preload(:user).order("users.name").to_a
    accounts = Account.current.where(owner_type: "Consumer", owner_id: consumers.map(&:id))
                      .preload(:payments).group_by(&:owner_id)

    consumers.map do |consumer|
      current = accounts.fetch(consumer.id, [])
      ConsumerRow.new(consumer:, amount: amount_of(current), status: status_of(current))
    end
  end

  def initialize(consumer)
    @consumer = consumer
  end

  def current_month
    current = accounts.select(&:current?)

    {
      amount: self.class.amount_of(current),
      status: self.class.status_of(current),
      meals_used: @consumer.subsidized_meals_used_this_month,
      meals_limit: @consumer.benefit_available,
      providers: meals_by_provider
    }
  end

  def months
    accounts.group_by(&:month)
            .map { |month, group| MonthRow.new(month:, accounts: group) }
            .sort_by { -it.month.jd }
  end

  private

  def accounts
    @accounts ||= @consumer.accounts
                           .preload(:payments, provider: :user, orders: { schedule: { menu: { provider: :user } } })
                           .to_a
  end

  # Mismo criterio que Consumer#subsidized_meals_used_this_month, abierto por proveedor.
  def meals_by_provider
    @consumer.orders
             .joins(schedule: { menu: { provider: :user } })
             .where(schedules: { date: Date.current.all_month })
             .where.not(status: [ :rejected, :cancelled ])
             .group("users.name")
             .sum(:amount)
             .sort
             .map { |name, meals| { name:, meals: } }
  end
end
