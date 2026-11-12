# frozen_string_literal: true

class Provider::PaymentDetailsProviderSerializer < ApplicationSerializer
  typelize_from Provider

  attributes :bank_name, :bank_account_details, :beneficiary
end
