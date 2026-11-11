# frozen_string_literal: true

class OrderAccount < ApplicationRecord
  belongs_to :account
  belongs_to :order

  validates :order_id, uniqueness: { scope: :account_id }
end

# == Schema Information
#
# Table name: order_accounts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  order_id   :bigint           not null
#
# Indexes
#
#  index_order_accounts_on_account_id               (account_id)
#  index_order_accounts_on_account_id_and_order_id  (account_id,order_id) UNIQUE
#  index_order_accounts_on_order_id                 (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (order_id => orders.id)
#
