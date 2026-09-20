# frozen_string_literal: true

class Admin::ConsumersController < Admin::InertiaController
  def index
    @query = params[:query].to_s.strip

    consumers = Consumer.joins(:user, :company).preload(:user, :company)
    if @query.present?
      consumers = consumers.where(
        "users.name ILIKE :q OR users.email ILIKE :q OR companies.name ILIKE :q", q: "%#{@query}%"
      )
    end

    @consumers = consumers.order("users.name")
  end

  def show
    @consumer = Consumer.preload(:user, :company).find(params[:id])
    @orders = @consumer.orders.preload(schedule: { menu: { provider: :user } }).order(created_at: :desc)
    @benefits = @consumer.benefits.order(due_date: :desc)

    accounts = @consumer.accounts.preload(:payments)
    @debts = accounts.pending
    @payments = accounts.flat_map(&:payments)
  end
end
