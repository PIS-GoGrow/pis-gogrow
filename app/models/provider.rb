# frozen_string_literal: true

class Provider < ApplicationRecord
  include SyncsUserRoles
  include Auditable

  enum :bank_account_type, { savings: 0, checking: 1 }, prefix: :bank_account, validate: { allow_nil: true }

  has_many :menus, dependent: :destroy
  has_many :schedules, through: :menus
  has_many :orders, through: :schedules
  has_many :accounts, dependent: :destroy
  has_many :invoices, through: :accounts
  has_many :schedules, through: :menus
  has_many :orders, through: :schedules
  has_many :payments, through: :accounts
  has_many :closures, class_name: "ProviderClosure", dependent: :destroy

  normalizes :tax_id, with: -> { it.gsub(/\D/, "") }
  normalizes :bank_name, :bank_account_number, :bank_account_holder, with: -> { it.strip }

  with_options on: :payment_details do
    validates :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id, presence: true
    validates :bank_account_number, format: { with: /\A[\d -]{4,30}\z/ }, allow_blank: true
    validates :tax_id, format: { with: /\A(\d{7,8}|\d{12})\z/ }, allow_blank: true
  end

  audits :home_delivery, :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id

  def onboarded?
    onboarding_completed_at.present?
  end

  def delivery_methods
    home_delivery? ? Order.delivery_methods.keys : [ "office" ]
  end

  def allows_delivery_method?(method)
    delivery_methods.include?(method.to_s)
  end

  def order_deadline_passed_today?
    deadline = order_deadline
    return false unless deadline

    today = Date.current
    deadline_at = Time.zone.local(today.year, today.month, today.day, deadline.hour, deadline.min, deadline.sec)
    Time.current >= deadline_at
  end

  # Mira todos los cierres en memoria: así un includes(:closures) sirve a todas
  # las fechas de un menú sin una consulta por cada una.
  def closed_on?(date)
    closures.any? { it.covers?(date) }
  end
end

# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  home_delivery  :boolean          default(TRUE), not null
#  order_deadline :time
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
