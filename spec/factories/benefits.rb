# frozen_string_literal: true

FactoryBot.define do
  factory :benefit do
    amount { 1 }
    description { "MyString" }
    percentage { 1 }
    due_date { "2026-09-03" }
    consumer { nil }
  end
end

# == Schema Information
#
# Table name: benefits
#
#  id                       :bigint           not null, primary key
#  amount                   :integer
#  description              :string
#  due_date                 :date
#  percentage               :integer
#  status                   :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint
#  consumer_id              :bigint           not null
#
# Indexes
#
#  index_benefits_on_benefit_configuration_id        (benefit_configuration_id)
#  index_benefits_on_consumer_id                     (consumer_id)
#  index_benefits_unique_active_per_consumer_config  (consumer_id,benefit_configuration_id) UNIQUE WHERE (status = 0)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
