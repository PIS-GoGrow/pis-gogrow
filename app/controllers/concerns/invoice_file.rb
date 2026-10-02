# frozen_string_literal: true

module InvoiceFile
  extend ActiveSupport::Concern

  private

  def send_invoice_file(invoice)
    send_data(
      invoice.file.download,
      filename: invoice.file.filename.to_s,
      type: invoice.file.content_type,
      disposition: params[:download].present? ? "attachment" : "inline"
    )
  end
end
