# frozen_string_literal: true

class Admin::DashboardIndexSerializer < ApplicationSerializer
  typelize today: :string
  attributes :today

  typelize payment_month: :string
  attributes :payment_month
end
