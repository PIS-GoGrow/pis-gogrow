# frozen_string_literal: true

class BenefitSerializer < ApplicationSerializer
  typelize_from Benefit

  attributes :id, :amount, :description, :percentage

  typelize :string?
  attribute :due_date do |benefit|
    benefit.due_date&.iso8601
  end
end

# == Schema Information
#
# Table name: benefits
#
#  id          :bigint           not null, primary key
#  amount      :integer
#  description :string
#  due_date    :date
#  percentage  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint           not null
#
# Indexes
#
#  index_benefits_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
