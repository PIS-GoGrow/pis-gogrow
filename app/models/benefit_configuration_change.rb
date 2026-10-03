# frozen_string_literal: true

# Registro de auditoría de los subsidios especiales: quién los creó, modificó o
# desactivó, con una foto de cómo quedaron después de cada cambio.
class BenefitConfigurationChange < ApplicationRecord
  enum :action, { created: 0, updated: 1, deactivated: 2 }

  belongs_to :benefit_configuration
  belongs_to :user
end

# == Schema Information
#
# Table name: benefit_configuration_changes
#
#  id                       :bigint           not null, primary key
#  action                   :integer          not null
#  details                  :jsonb            not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#  user_id                  :bigint           not null
#
# Indexes
#
#  idx_on_benefit_configuration_id_62ffbb5770      (benefit_configuration_id)
#  index_benefit_configuration_changes_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
