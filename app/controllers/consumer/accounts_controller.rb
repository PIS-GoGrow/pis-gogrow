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
  end

  private

  def set_account
    @account = Current.user.consumer.accounts.find(params[:id])
  end
end
