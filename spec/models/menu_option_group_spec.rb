# frozen_string_literal: true

require "rails_helper"

RSpec.describe MenuOptionGroup, type: :model do
  fixtures :menus, :providers, :menu_option_groups

  let(:menu) { menus(:sorrentinos) }

  describe "validations" do
    it "is valid with all attributes" do
      group = described_class.new(menu:, name: "Salsa", options: [ "Tuco", "Caruso" ], limit: 1)
      expect(group).to be_valid
    end

    it "requires a name" do
      group = described_class.new(menu:, name: nil, options: [ "Tuco" ], limit: 1)
      expect(group).not_to be_valid
      expect(group.errors[:name]).to be_present
    end

    it "requires limit greater than zero" do
      expect(described_class.new(menu:, name: "Salsa", limit: 0)).not_to be_valid
      expect(described_class.new(menu:, name: "Salsa", limit: -1)).not_to be_valid
    end

    it "requires limit to be an integer" do
      group = described_class.new(menu:, name: "Salsa", limit: 1.5)
      expect(group).not_to be_valid
      expect(group.errors[:limit]).to be_present
    end

    it "accepts empty options (grupo sin opciones cargadas aún)" do
      group = described_class.new(menu:, name: "Salsa", options: [], limit: 1)
      expect(group).to be_valid
    end

    it "rejects options with empty strings" do
      group = described_class.new(menu:, name: "Salsa", options: [ "Tuco", "" ], limit: 1)
      expect(group).not_to be_valid
      expect(group.errors[:options]).to be_present
    end

    it "rejects duplicate options" do
      group = described_class.new(menu:, name: "Salsa", options: [ "Tuco", "Tuco" ], limit: 1)
      expect(group).not_to be_valid
      expect(group.errors[:options]).to be_present
    end

    it "rejects duplicate options ignoring case and spaces" do
      group = described_class.new(menu:, name: "Salsa", options: [ "Tuco", " TUCO " ], limit: 1)
      expect(group).not_to be_valid
      expect(group.errors[:options]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a menu" do
      group = menu_option_groups(:salsa_sorrentinos)
      expect(group.menu).to eq(menu)
    end
  end
end

# == Schema Information
#
# Table name: menu_option_groups
#
#  id         :bigint           not null, primary key
#  limit      :integer          default(1), not null
#  name       :string           not null
#  options    :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_menu_option_groups_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
