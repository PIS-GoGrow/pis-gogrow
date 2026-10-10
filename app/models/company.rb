# frozen_string_literal: true

class Company < ApplicationRecord
  has_many :admins
  has_many :consumers
  has_many :accounts, as: :owner
  has_many :invoices, through: :accounts
  has_many :benefit_configurations

  validates :debt_alert_threshold, numericality: { only_integer: true, greater_than: 0 }

  def check_debt_alerts!
    consumers.includes(:user).find_each(&:check_debt_alert!)
  end
end

# == Schema Information
#
# Table name: companies
#
#  id                   :bigint           not null, primary key
#  address              :string
#  debt_alert_threshold :integer          default(2000), not null
#  name                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
