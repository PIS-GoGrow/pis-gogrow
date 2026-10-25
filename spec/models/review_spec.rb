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

  describe "en el contexto :consumer_review" do
    it "requiere una puntuación" do
      review = described_class.new(menu: menus(:milanesa), rating: nil)
      expect(review).not_to be_valid(:consumer_review)
      expect(review.errors[:rating]).to be_present
    end

    it "rechaza una puntuación fuera de 1..5" do
      review = described_class.new(menu: menus(:milanesa), rating: 6)
      expect(review).not_to be_valid(:consumer_review)
    end

    it "acepta una reseña vacía cuando hay puntuación válida" do
      review = described_class.new(menu: menus(:milanesa), rating: 4, description: nil)
      expect(review).to be_valid(:consumer_review)
    end

    it "rechaza una reseña de más de 200 caracteres" do
      review = described_class.new(menu: menus(:milanesa), rating: 4, description: "a" * 201)
      expect(review).not_to be_valid(:consumer_review)
    end
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
