# frozen_string_literal: true

# El proveedor de la pantalla de Pagos, con los datos de cobro que cargó en su
# perfil para que RR. HH. sepa a dónde transferir. El RUT no hace falta acá.
class Admin::PaymentProviderSerializer < ProviderSerializer
  typelize_from Provider

  attributes :bank_name, :bank_account_number, :bank_account_holder
end
