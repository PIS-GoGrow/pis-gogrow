# frozen_string_literal: true

class ProviderPasswordResetCodesShowSerializer < ApplicationSerializer
  typelize email: :string, resend_in: :number
  attributes :email, :resend_in
end
