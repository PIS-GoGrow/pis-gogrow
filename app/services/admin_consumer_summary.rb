# frozen_string_literal: true

class AdminConsumerSummary
  # Estado que resume varias cuentas del mismo mes: el que más atención pide.
  STATUS_PRIORITY = %w[pending rejected submitted approved].freeze

  ConsumerRow = Data.define(:consumer, :amount, :status) do
    delegate :id, to: :consumer

    def name = consumer.user.name

    def email = consumer.user.email

    def avatar_url = consumer.user.avatar_url
  end

  ProviderRow = Data.define(:id, :name, :amount, :status, :receipt_url)

  MonthRow = Data.define(:month, :accounts) do
    def key = month.strftime("%Y-%m")

    def year = month.year

    def amount = AdminConsumerSummary.amount_of(accounts)

    def status = AdminConsumerSummary.status_of(accounts)

    def orders
      accounts.flat_map { it.orders.select(&:confirmed?) }.sort_by { [ it.delivery_date&.jd || 0, it.created_at ] }.reverse
    end

    def subsidy = orders.sum { it.subsidy || 0 }.to_f

    def providers
      accounts
        .map do |account|
          ProviderRow.new(
            id: account.provider_id,
            name: account.provider.user.name,
            amount: account.amount.to_f,
            status: account.collection_status,
            receipt_url: receipt_url_of(account)
          )
        end
        .sort_by(&:name)
    end

    private

    def receipt_url_of(account)
      payment = account.payments.select { it.receipt.attached? }.max_by(&:created_at)
      Rails.application.routes.url_helpers.receipt_admin_payment_path(payment) if payment
    end
  end

  def self.amount_of(accounts) = accounts.sum { it.amount || 0 }.to_f

  # nil cuando no hay nada que cobrar: la pantalla lo muestra como "Sin consumos".
  def self.status_of(accounts)
    statuses = accounts.select { it.amount.to_d.positive? }.map(&:collection_status)
    return if statuses.empty?

    STATUS_PRIORITY.find { it.in?(statuses) }
  end

  def self.rows_for(company, month: Date.current)
    rows(company) { it.where(month: month.beginning_of_month) }
  end

  # Lo de este mes más lo que quedó sin pagar de los anteriores: mirando un solo
  # mes no se ve lo que el empleado todavía debe de antes.
  def self.debt_rows_for(company)
    rows(company) { it.where(month: Date.current.beginning_of_month).or(it.pending) }
  end

  def self.rows(company)
    consumers = company.consumers.joins(:user).preload(:user).order("users.name").to_a
    accounts = yield(Account.where(owner_type: "Consumer", owner_id: consumers.map(&:id)))
               .preload(:payments).group_by(&:owner_id)

    consumers.map do |consumer|
      owed = accounts.fetch(consumer.id, [])
      ConsumerRow.new(consumer:, amount: amount_of(owed), status: status_of(owed))
    end
  end
  private_class_method :rows

  def initialize(consumer)
    @consumer = consumer
  end

  def current_month
    current = accounts.select(&:current?)

    {
      amount: self.class.amount_of(current),
      status: self.class.status_of(current),
      meals_used: @consumer.monthly_benefit_used_this_month,
      meals_limit: @consumer.monthly_benefit_available,
      providers: meals_by_provider
    }
  end

  def months
    accounts_by_month = accounts.group_by(&:month)
    history_years = accounts_by_month.keys.map(&:year).uniq.select { it <= Date.current.year }.sort.reverse
    years = [ Date.current.year, *history_years.reject { it == Date.current.year } ]

    years.flat_map do |year|
      last_month = year == Date.current.year ? Date.current.month : 12

      last_month.downto(1).map do |month_number|
        month = Date.new(year, month_number, 1)
        MonthRow.new(month:, accounts: accounts_by_month.fetch(month, []))
      end
    end
  end

  private

  def accounts
    @accounts ||= @consumer.accounts
                           .preload({ payments: { receipt_attachment: :blob } }, provider: :user, orders: { schedule: { menu: { provider: :user } } })
                           .to_a
  end

  def meals_by_provider
    @consumer.monthly_benefit_usages
      .joins(order: { schedule: { menu: { provider: :user } } })
      .group("users.name")
      .sum(:benefit_used)
      .sort
      .map { |name, meals| { name:, meals: } }
  end
end
