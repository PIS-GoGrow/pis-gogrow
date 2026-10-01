# frozen_string_literal: true

class Admin::InvoicesController < Admin::InertiaController
  include InvoiceFile

  # Las facturas son las que el proveedor le emite a la empresa, así que salen
  # de las cuentas de la empresa de quien mira y no de todas las de la base.
  def index
    @invoices = Invoice
      .joins(:account)
      .merge(Current.user.admin.company.accounts)
      .includes(account: { provider: :user })
      .order(Arel.sql("accounts.month DESC"), issued_on: :desc)
  end

  def file
    send_invoice_file(Invoice.find(params[:id]))
  end
end
