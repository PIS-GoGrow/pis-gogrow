# frozen_string_literal: true

FactoryBot.define do
  factory :provider do
    email { "MyString" }
    username { "MyString" }
    order_deadline { "2026-09-03 20:54:50" }
  end
end

# == Schema Information
#
# Table name: providers
#
#  id                            :bigint           not null, primary key
#  bank_account_holder           :string
#  bank_account_number           :string
#  bank_account_type             :integer
#  bank_name                     :string
#  deliveries_configured_at      :datetime
#  home_delivery                 :boolean          default(TRUE), not null
#  notifications_configured_at   :datetime
#  onboarding_completed_at       :datetime
#  order_deadline                :time
#  order_deadline_configured_at  :datetime
#  payment_details_configured_at :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  tax_id                        :string
#  user_id                       :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
