# frozen_string_literal: true

class Admin::InvoiceSerializer < ApplicationSerializer
  typelize_from Invoice

  attributes :id, :status

  # Fechas y montos se arman en el servidor: el SSR corre en UTC y un formato
  # hecho en el browser no coincidiría con el HTML hidratado.
  typelize :string
  attribute :period do |invoice|
    I18n.l(invoice.account.month, format: "%B %Y")
  end

  typelize :string
  attribute :issued_on do |invoice|
    I18n.l(invoice.issued_on, format: "%d/%m/%y")
  end

  typelize :string
  attribute :provider_name do |invoice|
    invoice.account.provider.user&.name || I18n.t("pages.admin.invoices.index.no_provider")
  end

  typelize :number
  attribute :total_amount do |invoice|
    invoice.total_amount.to_f
  end

  # El consumo del período, para que RR. HH. pueda contrastarlo con lo facturado.
  typelize :number?
  attribute :period_amount do |invoice|
    invoice.account.amount&.to_f
  end

  typelize :string
  attribute :file_name do |invoice|
    invoice.file.filename.to_s
  end

  typelize :string
  attribute :file_size do |invoice|
    ActiveSupport::NumberHelper.number_to_human_size(invoice.file.byte_size)
  end
end
