# frozen_string_literal: true

class Admin::InvoicesController < Admin::InertiaController
  include InvoiceFile

  # Las facturas son las que el proveedor le emite a la empresa, así que salen
  # de las cuentas de la empresa de quien mira y no de todas las de la base.
  def index
    @invoices = company_invoices
      .includes(account: { provider: :user })
      .order(Arel.sql("accounts.month DESC"), issued_on: :desc)
  end

  # El find va sobre las facturas de la empresa y no sobre Invoice: pedir la de
  # otra empresa por su id tiene que ser un 404, no el archivo ajeno.
  def file
    send_invoice_file(company_invoices.find(params[:id]))
  end

  private

  def company_invoices
    Current.user.admin.company.invoices
  end
end
