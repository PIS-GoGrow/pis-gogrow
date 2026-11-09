# frozen_string_literal: true

# El proveedor de la pantalla de Pagos, con los datos de cobro que cargó en su
# perfil para que RR. HH. y el consumidor sepan a dónde transferir.
class PaymentProviderSerializer < ProviderSerializer
  typelize_from Provider

  attributes :bank_name, :bank_account_details, :beneficiary

  typelize :boolean
  attribute :payment_details_complete, &:payment_details_complete?
end
