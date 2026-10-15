# frozen_string_literal: true

class Provider::PaymentDetailsProviderSerializer < ApplicationSerializer
  typelize_from Provider

  attributes :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id
end
