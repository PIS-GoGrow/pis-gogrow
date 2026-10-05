# frozen_string_literal: true

# Representa un plato de un proveedor. Su disponibilidad se asigna con Schedule.
# Un plato guardado tiene base_menu_id nil. Una variante es una copia del plato
# con otros datos para las fechas valid_from..valid_until: las programaciones de
# esas fechas apuntan a la variante y el resto sigue usando el plato guardado.
class Menu < ApplicationRecord
  belongs_to :provider
  belongs_to :base_menu, class_name: "Menu", optional: true
  belongs_to :modified_by, class_name: "User", optional: true

  has_many :schedules, dependent: :destroy
  has_many :reviews, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :option_groups, class_name: "MenuOptionGroup", dependent: :destroy
  has_many :variants, class_name: "Menu", foreign_key: :base_menu_id, dependent: :destroy, inverse_of: :base_menu
  has_many :agendas, class_name: "MenuAgenda", dependent: :destroy

  accepts_nested_attributes_for :option_groups, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :description, presence: true
  validates :price, comparison: { greater_than: 0 }

  scope :saved, -> { where(base_menu_id: nil) }

  def provider_name
    provider.user&.name || "Proveedor"
  end

  def saved_menu
    base_menu || self
  end

  def variant?
    base_menu_id.present?
  end

  def family_ids
    [ saved_menu.id, *saved_menu.variants.ids ]
  end

  def valid_on?(date)
    (valid_from..valid_until).cover?(date)
  end

  # La agenda que rige de hoy en adelante, la que se muestra al editar.
  def current_agenda
    agendas.where(ends_on: nil).or(agendas.where(ends_on: Date.current..)).order(:starts_on).last
  end

  # El id del grupo se copia junto con el nombre: es lo que permite cruzar el
  # snapshot con la elección que el empleado guardó en el pedido, para que el
  # proveedor vea lo pidió y no lo que el plato ofrece.
  def option_groups_snapshot
    option_groups.map do |g|
      { "id" => g.id, "name" => g.name, "options" => g.options, "limit" => g.limit }
    end
  end

  def build_variant(valid_from:, valid_until:)
    saved_menu.variants.build(provider:, name:, description:, price:, valid_from:, valid_until:).tap do |variant|
      option_groups.each { |g| variant.option_groups.build(name: g.name, options: g.options, limit: g.limit) }
    end
  end
end

# == Schema Information
#
# Table name: menus
#
#  id              :bigint           not null, primary key
#  description     :string
#  modified_at     :datetime
#  modified_values :jsonb
#  name            :string
#  price           :decimal(10, 2)
#  valid_from      :date
#  valid_until     :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  base_menu_id    :bigint
#  modified_by_id  :bigint
#  provider_id     :bigint           not null
#
# Indexes
#
#  index_menus_on_base_menu_id    (base_menu_id)
#  index_menus_on_modified_by_id  (modified_by_id)
#  index_menus_on_provider_id     (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (base_menu_id => menus.id)
#  fk_rails_...  (modified_by_id => users.id)
#  fk_rails_...  (provider_id => providers.id)
#
