# frozen_string_literal: true

class ConsumerBenefitConfiguration < ApplicationRecord
  belongs_to :benefit_configuration
  belongs_to :consumer
end

# == Schema Information
#
# Table name: benefit_configuration_consumers
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#  consumer_id              :bigint           not null
#
# Indexes
#
#  idx_on_benefit_configuration_id_08b93c0545            (benefit_configuration_id)
#  index_benefit_configuration_consumers_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
