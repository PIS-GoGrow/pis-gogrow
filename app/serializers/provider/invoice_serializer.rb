# frozen_string_literal: true

class Provider::InvoiceSerializer < ApplicationSerializer
  typelize_from Invoice

  attributes :id, :status

  typelize :boolean
  attribute :removable, &:removable?

  typelize :number
  attribute :total_amount do |invoice|
    invoice.total_amount.to_f
  end

  # Formateada en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :issued_on do |invoice|
    invoice.issued_on.strftime("%d/%m/%y")
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
