# frozen_string_literal: true

class AddOrderAndConsumerToReviews < ActiveRecord::Migration[8.1]
  def change
    # Nullable: las reseñas que ya existen son agregados por plato (se muestran en
    # el detalle) y no cuelgan de un pedido. El índice único evita calificar dos
    # veces el mismo pedido; Postgres considera distintos los NULL, así que no
    # choca con esas reseñas sin pedido.
    add_reference :reviews, :order, foreign_key: true, index: { unique: true }
    add_reference :reviews, :consumer, foreign_key: true
  end
end
