# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  before_create do
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end

  enum :role, { provider: 0, admin: 1, consumer: 2 }

  validate :role_available_for_user

  private

  # Validar que el rol con el que se va a iniciar la sesión sea válido
  # para el usuario.
  def role_available_for_user
    return if role.blank? || user.blank?

    unless user.public_send("#{role}?")
      errors.add(:role, "no está disponible para este usuario")
    end
  end
end

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string
#  role       :integer          not null
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
