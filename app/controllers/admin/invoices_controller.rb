# frozen_string_literal: true

class Admin::InvoicesController < Admin::InertiaController
  def file
    invoice = Invoice.find(params[:id])

    send_data(
      invoice.file.download,
      filename: invoice.file.filename.to_s,
      type: invoice.file.content_type,
      disposition: params[:download].present? ? "attachment" : "inline"
    )
  end
end
