# frozen_string_literal: true

class PaymentSerializer < ApplicationSerializer
  typelize_from Payment

  attributes :id, :status, :created_at
end

# == Schema Information
#
# Table name: payments
#
#  id         :bigint           not null, primary key
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_payments_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
