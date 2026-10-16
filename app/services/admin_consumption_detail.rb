# frozen_string_literal: true

# El detalle del consumo de una empresa en un mes, un bloque por proveedor: lo
# que muestra el panel "Ver detalle del consumo" del Inicio y de Pagos. Los importes son los
# de la cuenta de la empresa (el subsidio y su IVA) y los días salen de los
# pedidos confirmados de esa cuenta.
class AdminConsumptionDetail
  def initialize(company, month)
    @company = company
    @month = month.beginning_of_month
  end

  # nil si la empresa no le debe nada a nadie ese mes: no hay qué detallar.
  def to_h
    return if accounts.empty?

    {
      month: I18n.l(@month, format: :month_name_year).upcase_first,
      providers: accounts.sort_by { it.provider.user.name.downcase }.map { provider_detail(it) }
    }
  end

  private

  def accounts
    @accounts ||= @company.accounts.where(month: @month).where.not(amount: ..0)
                          .preload(:payments, provider: :user).to_a
  end

  def provider_detail(account)
    orders = orders_by_account.fetch(account.id, [])

    {
      id: account.provider_id,
      name: account.provider.user.name,
      meals: orders.sum(&:amount),
      subtotal: account.amount.to_f,
      vat_rate: (account.vat_rate.to_d * 100).to_f,
      vat_amount: account.vat_amount.to_f,
      payable_amount: account.payable_amount.to_f,
      days: ConsumptionDays.call(orders) do |order|
        {
          id: order.id,
          consumer_name: order.consumer.user.name,
          avatar_url: order.consumer.user.avatar_url,
          meals: order.amount,
          employee_amount: (order.discounted_price || order.price).to_f,
          company_amount: (order.subsidy || 0).to_f
        }
      end
    }
  end

  def orders_by_account
    @orders_by_account ||=
      Order.confirmed.joins(:order_accounts)
           .where(order_accounts: { account_id: accounts.map(&:id) })
           .select("orders.*", "order_accounts.account_id AS detail_account_id")
           .preload(:schedule, consumer: :user)
           .group_by(&:detail_account_id)
  end
end
