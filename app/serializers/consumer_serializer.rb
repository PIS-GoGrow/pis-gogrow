# frozen_string_literal: true

class ConsumerSerializer < ApplicationSerializer
  typelize_from Consumer

  attributes :id, :address

  typelize :string
  attribute :name do |consumer|
    consumer.user.name
  end

  typelize :string
  attribute :email do |consumer|
    consumer.user.email
  end

  typelize :string
  attribute :company_name do |consumer|
    consumer.company.name
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
