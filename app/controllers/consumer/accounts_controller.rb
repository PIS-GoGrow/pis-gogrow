# frozen_string_literal: true

class Consumer::AccountsController < Consumer::InertiaController
  before_action :set_account, only: [:show]
  def index
    history = params[:type] == "history"
    providers = Provider.all
    current_month_spending = Current.user.consumer.current_month_spending

    accounts = Current.user.consumer.accounts
    if history
      accounts = accounts.history.includes(:payments)
    else
      accounts = accounts.pending.includes(:payments)
    end

    render inertia: {
      accounts: AccountSerializer.new(accounts).as_json,
      providers: ProviderSerializer.new(providers).as_json,
      history:,
      current_month_spending:
    }
  end

  def show
    orders = @account.orders.confirmed
    month = I18n.l(@account.month, format: :month_year)
    amount = @account.amount

    data = {
      orders: SimplifiedOrderSerializer.new(orders).as_json,
      month:,
      amount:
    }

    respond_to do |format|
      format.json { render json: data }
      format.html { render inertia: data }
    end
  end

  private

  def set_account
    @account = Current.user.consumer.accounts.find(params[:id])
  end
end
