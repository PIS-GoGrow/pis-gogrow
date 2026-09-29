# frozen_string_literal: true

class Provider::InvoicesController < Provider::InertiaController
  before_action :set_invoice, only: [ :destroy, :file ]

  # La cuenta se busca entre los períodos de empresa del proveedor autenticado:
  # un account_id ajeno o de un empleado es un 404, no una factura mal asociada.
  def create
    account = Current.user.provider.accounts.where(owner_type: "Company").find(params.require(:invoice).fetch(:account_id))
    invoice = account.invoices.build(invoice_params)

    if invoice.save
      redirect_back_or_to provider_collections_path, notice: t("flash.invoice_uploaded"), status: :see_other
    else
      redirect_back_or_to provider_collections_path, inertia: { errors: invoice.errors.to_hash }, status: :see_other
    end
  end

  def destroy
    if @invoice.removable?
      @invoice.destroy!
      redirect_back_or_to provider_collections_path, notice: t("flash.invoice_removed"), status: :see_other
    else
      redirect_back_or_to provider_collections_path, alert: t("validations.invoice_not_removable"), status: :see_other
    end
  end

  def file
    send_data(
      @invoice.file.download,
      filename: @invoice.file.filename.to_s,
      type: @invoice.file.content_type,
      disposition: params[:download].present? ? "attachment" : "inline"
    )
  end

  private

  def set_invoice
    @invoice = Current.user.provider.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:issued_on, :total_amount, :file)
  end
end
