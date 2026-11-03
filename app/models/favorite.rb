# frozen_string_literal: true

# Un plato o proveedor que el empleado marcó a mano. Los platos se guardan por
# su plato guardado, no por la variante, para que el favorito siga valiendo
# cuando el proveedor programa una variante.
class Favorite < ApplicationRecord
  KINDS = { "menus" => "Menu", "providers" => "Provider" }.freeze

  belongs_to :consumer
  belongs_to :favoritable, polymorphic: true

  validates :favoritable_type, inclusion: { in: KINDS.values }
  validates :favoritable_id, uniqueness: { scope: [ :consumer_id, :favoritable_type ] }

  before_validation :use_saved_menu

  private

  def use_saved_menu
    self.favoritable = favoritable.saved_menu if favoritable.is_a?(Menu)
  end
end

# == Schema Information
#
# Table name: favorites
#
#  id               :bigint           not null, primary key
#  favoritable_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  consumer_id      :bigint           not null
#  favoritable_id   :bigint           not null
#
# Indexes
#
#  index_favorites_on_consumer_and_favoritable  (consumer_id,favoritable_type,favoritable_id) UNIQUE
#  index_favorites_on_consumer_id               (consumer_id)
#  index_favorites_on_favoritable               (favoritable_type,favoritable_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
