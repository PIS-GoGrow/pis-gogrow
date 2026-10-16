# frozen_string_literal: true

class Provider::CollectionsController < Provider::InertiaController
  def index
    summary = ProviderCollectionSummary.new(provider: Current.user.provider)

    @sales = summary.sales
    @sales_detail = summary.sales_detail
    @outstanding = summary.outstanding
    @clients = summary.clients
    @pending = summary.pending
    @history = summary.history
  end

  # El find va sobre las cuentas del proveedor y no sobre Account: pedir la de
  # otro proveedor tiene que ser un 404, no una cuenta ajena.
  def show
    account = Current.user.provider.accounts.preload(:owner, invoices: { file_attachment: :blob }).find(params[:id])

    ActiveRecord::Associations::Preloader.new(
      records: [ account ], associations: :orders,
      scope: Order.confirmed.preload(consumer: :user, schedule: :menu).order(:created_at)
    ).call
    ActiveRecord::Associations::Preloader.new(
      records: [ account ], associations: :payments,
      scope: Payment.preload(receipt_attachment: :blob).order(created_at: :desc)
    ).call

    @account = ProviderCollectionSummary.row_for(account)
    @orders = account.orders.to_a
    @payments = account.payments.to_a
  end
end
