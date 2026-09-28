# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menu, type: :model do
  fixtures :menus, :providers, :reviews, :schedules, :menu_option_groups

  let(:provider) { providers(:tuviandita) }

  describe "validations" do
    it "is valid with valid attributes" do
      menu = described_class.new(name: "Pastel de papa", price: 280, provider:)
      expect(menu).to be_valid
    end

    it "requires a name" do
      menu = described_class.new(name: nil, price: 280, provider:)
      expect(menu).not_to be_valid
      expect(menu.errors[:name]).to be_present
    end

    it "requires a price greater than zero" do
      expect(described_class.new(name: "Plato", price: 0, provider:)).not_to be_valid
      expect(described_class.new(name: "Plato", price: -10, provider:)).not_to be_valid
      expect(described_class.new(name: "Plato", price: 150, provider:)).to be_valid
    end

    it "requires a provider" do
      menu = described_class.new(name: "Plato", price: 150, provider: nil)
      expect(menu).not_to be_valid
      expect(menu.errors[:provider]).to be_present
    end
  end

  describe "associations" do
    it "destroys dependent schedules on delete" do
      menu = menus(:milanesa)
      expect(menu.schedules).to be_present
      expect { menu.destroy }.to change(Schedule, :count).by(-menu.schedules.count)
    end

    it "destroys dependent reviews on delete" do
      menu = menus(:sorrentinos)
      expect(menu.reviews).to be_present
      expect { menu.destroy }.to change(Review, :count).by(-menu.reviews.count)
    end
  end

  describe "option_groups" do
    it "can have multiple option groups" do
      menu = menus(:sorrentinos)
      expect(menu.option_groups.count).to eq(2)
    end

    it "destroys option groups when menu is deleted" do
      menu = menus(:sorrentinos)
      expect { menu.destroy }.to change(MenuOptionGroup, :count).by(-2)
    end
  end
end

# == Schema Information
#
# Table name: menus
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  price       :decimal(10, 2)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_menus_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
