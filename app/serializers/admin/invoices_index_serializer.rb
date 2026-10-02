# frozen_string_literal: true

class Admin::InvoicesIndexSerializer < ApplicationSerializer
  has_many :invoices, resource: Admin::InvoiceSerializer
end
