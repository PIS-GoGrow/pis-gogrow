# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review, type: :model do
  fixtures :menus, :reviews

  it "belongs to a menu" do
    expect(reviews(:sorrentinos_mas_nueva).menu).to eq(menus(:sorrentinos))
  end

  it "is invalid without a menu" do
    review = described_class.new(description: "Rico", rating: 5)
    expect(review).not_to be_valid
  end

  it "is valid with a menu and optional fields blank" do
    review = described_class.new(menu: menus(:milanesa), description: nil, rating: nil)
    expect(review).to be_valid
  end

  it "is valid with a description and rating" do
    review = described_class.new(menu: menus(:milanesa), description: "Muy rico", rating: 5)
    expect(review).to be_valid
  end
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
#  menu_id     :bigint           not null
#
# Indexes
#
#  index_reviews_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
