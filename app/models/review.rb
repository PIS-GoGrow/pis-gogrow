# frozen_string_literal: true

class Review < ApplicationRecord
  belongs_to :menu
  # Opcionales: las reseñas que ya existen son agregados por plato y no cuelgan de
  # un pedido ni de un empleado. Las que crea el empleado al calificar sí los
  # llevan, y el controller garantiza que estén.
  belongs_to :order, optional: true
  belongs_to :consumer, optional: true

  normalizes :description, with: ->(value) { value.presence }

  # Las reglas de IBP-011 valen solo cuando el empleado califica (contexto
  # :consumer_review): las reseñas que se muestran por plato pueden no tener
  # puntaje ni texto, así que el contrato por defecto del modelo no los exige.
  validates :rating, presence: true, inclusion: { in: 1..5 }, on: :consumer_review
  validates :description, length: { maximum: 200 }, on: :consumer_review
end

# == Schema Information
#
# Table name: reviews
#
#  id          :bigint           not null, primary key
#  description :string
#  rating      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint
#  menu_id     :bigint           not null
#  order_id    :bigint
#
# Indexes
#
#  index_reviews_on_consumer_id  (consumer_id)
#  index_reviews_on_menu_id      (menu_id)
#  index_reviews_on_order_id     (order_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (menu_id => menus.id)
#  fk_rails_...  (order_id => orders.id)
#
