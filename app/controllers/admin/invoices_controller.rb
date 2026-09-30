# frozen_string_literal: true

class Admin::InvoicesController < Admin::InertiaController
  include InvoiceFile

  def file
    send_invoice_file(Invoice.find(params[:id]))
  end
end
