# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment, type: :model do
  it "defaults to pending" do
    expect(Payment.new.status).to eq("pending")
  end
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
