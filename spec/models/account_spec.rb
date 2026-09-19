# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
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
#  idx_on_owner_type_owner_id_provider_id_month_49d9020441  (owner_type,owner_id,provider_id,month) UNIQUE
#  index_accounts_on_owner                                  (owner_type,owner_id)
#  index_accounts_on_provider_id                            (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
