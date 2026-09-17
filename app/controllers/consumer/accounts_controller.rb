# frozen_string_literal: true

class Consumer::AccountsController < Consumer::InertiaController
  def index
  	history = param[:type] == "history"
  	providers = Provider.all
  	
  	accounts = Current.user.consumer.accounts
  	if history
  		accounts = accounts.history.includes(:orders, :payments)
  	else
  		accounts = accounts.pending.includes(:orders, :payments)
  	end

  	render inertia: { accounts:, providers:, history: }
  end
end
