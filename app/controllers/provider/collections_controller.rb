# frozen_string_literal: true

class Provider::CollectionsController < Provider::InertiaController
  def index
    summary = ProviderCollectionSummary.new(provider: Current.user.provider)

    @sales = summary.sales
    @outstanding = summary.outstanding
    @clients = summary.clients
    @pending = summary.pending
    @history = summary.history
  end

  # El find va sobre las cuentas del proveedor y no sobre Account: pedir la de
  # otro proveedor tiene que ser un 404, no una cuenta ajena.
  def show
    account = Current.user.provider.accounts.preload(:payments, :owner).find(params[:id])

    @account = ProviderCollectionSummary.row_for(account)
    @orders = account.orders.confirmed.preload(consumer: :user, schedule: :menu).order(:created_at)
    @payments = account.payments.order(created_at: :desc)
  end
end
