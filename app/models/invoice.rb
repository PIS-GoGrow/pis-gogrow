# frozen_string_literal: true

# Factura que el proveedor le emite a GoGrow por el subsidio de un período, que
# es la cuenta de la empresa con ese proveedor para ese mes.
class Invoice < ApplicationRecord
  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  belongs_to :account

  has_one_attached :file

  validates :issued_on, presence: true, comparison: { less_than_or_equal_to: -> { Date.current } }
  validates :total_amount, numericality: { greater_than: 0 }
  validate :account_belongs_to_a_company
  validate :period_accepts_a_new_invoice, on: :create
  validate :file_is_attached
  validate :file_has_allowed_type
  validate :file_is_within_size_limit

  # Mientras nadie la revisó, el proveedor puede sacarla y subir otra.
  def removable?
    pending?
  end

  private

  def account_belongs_to_a_company
    errors.add(:account, :not_company) if account && account.owner_type != "Company"
  end

  # Solo una rechazada deja lugar a otra: si no, el período quedaría con dos
  # facturas vigentes para el mismo cobro.
  def period_accepts_a_new_invoice
    return unless account&.invoices&.where(status: [ :pending, :approved ])&.exists?

    errors.add(:base, :already_invoiced)
  end

  def file_is_attached
    errors.add(:file, :required) unless file.attached?
  end

  def file_has_allowed_type
    return unless file.attached?
    return if file.blob.content_type.in?([ "application/pdf", "image/jpeg", "image/png" ])

    errors.add(:file, :invalid_content_type)
  end

  def file_is_within_size_limit
    return unless file.attached?
    return unless file.blob.byte_size > 10.megabytes

    errors.add(:file, :too_large)
  end
end

# == Schema Information
#
# Table name: invoices
#
#  id           :bigint           not null, primary key
#  issued_on    :date             not null
#  status       :integer          default(0), not null
#  total_amount :decimal(10, 2)   not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Indexes
#
#  index_invoices_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
