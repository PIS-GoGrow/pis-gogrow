# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menu, type: :model do
  fixtures :menus, :providers, :reviews, :schedules, :menu_option_groups, :users

  let(:provider) { providers(:tuviandita) }

  describe "validations" do
    it "is valid with valid attributes" do
      menu = described_class.new(name: "Pastel de papa", description: "Rico pastel", price: 280, provider:)
      expect(menu).to be_valid
    end

    it "requires a name" do
      menu = described_class.new(name: nil, description: "Rico pastel", price: 280, provider:)
      expect(menu).not_to be_valid
      expect(menu.errors[:name]).to be_present
    end

    it "requires a price greater than zero" do
      expect(described_class.new(name: "Plato", description: "Rico plato", price: 0, provider:)).not_to be_valid
      expect(described_class.new(name: "Plato", description: "Rico plato", price: -10, provider:)).not_to be_valid
      expect(described_class.new(name: "Plato", description: "Rico plato", price: 150, provider:)).to be_valid
    end

    it "requires a provider" do
      menu = described_class.new(name: "Plato", description: "Rico plato", price: 150, provider: nil)
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

    it "can belong to a user who modified it" do
      menu = menus(:milanesa)
      expect(menu.modified_by).to be_nil
      menu.modified_by = users(:provider_user)
      expect(menu.modified_by).to eq(users(:provider_user))
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

  describe "#provider_name" do
    it "returns the user name of the provider" do
      menu = menus(:milanesa)
      expect(menu.provider_name).to eq(menu.provider.user.name)
    end

    it "falls back to 'Proveedor' when provider has no user" do
      menu = menus(:milanesa)
      allow(menu.provider).to receive(:user).and_return(nil)
      expect(menu.provider_name).to eq("Proveedor")
    end
  end

  describe "reviews ordering" do
    it "orders reviews by created_at desc" do
      menu = menus(:sorrentinos)
      dates = menu.reviews.pluck(:created_at)
      expect(dates).to eq(dates.sort.reverse)
    end
  end

  describe "#agenda_on" do
    let(:menu) { menus(:milanesa) }

    it "returns nil when the menu has no agendas" do
      expect(menu.agenda_on(Date.current)).to be_nil
    end

    it "returns an ongoing open-ended agenda covering the date" do
      agenda = menu.agendas.create!(weekdays: [ 1, 3 ], starts_on: Date.current, amount: 5)
      expect(menu.agenda_on(Date.current + 2.days)).to eq(agenda)
    end

    it "returns nil when an open-ended agenda starts after the given date" do
      menu.agendas.create!(weekdays: [ 1, 3 ], starts_on: Date.current + 3.days, amount: 5)
      expect(menu.agenda_on(Date.current)).to be_nil
    end

    it "returns a range agenda when the date falls within its boundaries" do
      agenda = menu.agendas.create!(
        weekdays: [ 2, 4 ],
        starts_on: Date.current,
        ends_on: Date.current + 7.days,
        amount: 8
      )
      expect(menu.agenda_on(Date.current + 3.days)).to eq(agenda)
    end

    it "returns nil when the date is after the range agenda's end date" do
      menu.agendas.create!(
        weekdays: [ 2, 4 ],
        starts_on: Date.current - 10.days,
        ends_on: Date.current - 2.days,
        amount: 8
      )
      expect(menu.agenda_on(Date.current)).to be_nil
    end

    it "returns the latest matching agenda by starts_on when multiple agendas exist" do
      menu.agendas.create!(weekdays: [ 1 ], starts_on: Date.current - 5.days, amount: 5)
      newer_agenda = menu.agendas.create!(weekdays: [ 2 ], starts_on: Date.current - 1.day, amount: 10)

      expect(menu.agenda_on(Date.current)).to eq(newer_agenda)
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
