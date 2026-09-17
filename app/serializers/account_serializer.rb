# frozen_string_literal: true

class AccountSerializer < ApplicationSerializer
  attributes :id, :month, :amount, :provider_id

  many :payments, resource: PaymentSerializer
end

# == Schema Information
#
# Table name: accounts
#
#  id          :bigint           not null, primary key
#  amount      :decimal(10, 2)
#  month       :date
#  owner_type  :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_accounts_on_owner        (owner_type,owner_id)
#  index_accounts_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
