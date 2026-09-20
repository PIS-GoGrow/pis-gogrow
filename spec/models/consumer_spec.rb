# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consumer, type: :model do
  fixtures :consumers, :companies, :providers

  let(:consumer) { consumers(:one) }
  let(:company_address) { companies(:gogrow).address }

  describe "#delivery_for" do
    it "derives office when the company address is chosen" do
      expect(consumer.delivery_for(providers(:tuviandita), company_address))
        .to eq({ delivery_method: "office", address: company_address })
    end

    it "derives home when another address is chosen and the provider delivers home" do
      expect(consumer.delivery_for(providers(:tuviandita), consumer.address))
        .to eq({ delivery_method: "home", address: consumer.address })
    end

    it "forces office with the company address for an office-only provider" do
      expect(consumer.delivery_for(providers(:office_provider), consumer.address))
        .to eq({ delivery_method: "office", address: company_address })
    end
  end
end

# == Schema Information
#
# Table name: consumers
#
#  id         :bigint           not null, primary key
#  address    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
