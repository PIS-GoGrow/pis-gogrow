# frozen_string_literal: true

class ConsumerBenefitConfiguration < ApplicationRecord
  belongs_to :benefit_configuration
  belongs_to :consumer
end

# == Schema Information
#
# Table name: consumer_benefit_configurations
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#  consumer_id              :bigint           not null
#
# Indexes
#
#  idx_on_benefit_configuration_id_5005c4988d            (benefit_configuration_id)
#  index_consumer_benefit_configurations_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
