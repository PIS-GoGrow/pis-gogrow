# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeliveryAddress, type: :model do
  fixtures :consumers, :companies, :users

  def build_address(**attributes)
    consumers(:one).saved_addresses.new(name: "Casa", street: "Ellauri 1234", **attributes)
  end

  it "is valid with a name and a street with its door number" do
    expect(build_address).to be_valid
  end

  it "requires a name and a street" do
    address = build_address(name: " ", street: "")

    expect(address).not_to be_valid
    expect(address.errors.details).to include(name: [ { error: :blank } ], street: [ { error: :blank } ])
  end

  it "rejects a street without a door number" do
    address = build_address(street: "Ellauri")

    expect(address).not_to be_valid
    expect(address.errors.details[:street]).to include(error: :invalid, value: "Ellauri")
  end

  it "limits the length of every field" do
    address = build_address(name: "a" * 41, street: "Calle #{"a" * 120} 1", apartment: "b" * 41)

    expect(address).not_to be_valid
    expect(address.errors.attribute_names).to contain_exactly(:name, :street, :apartment)
  end

  it "squishes the fields and drops a blank apartment" do
    address = build_address(name: "  Flora   Café ", street: " Canelones  892 ", apartment: "  ")

    expect(address).to have_attributes(name: "Flora Café", street: "Canelones 892", apartment: nil)
  end

  describe "#full_address" do
    it "joins the street and the apartment" do
      expect(build_address(apartment: "Apto 502").full_address).to eq("Ellauri 1234, Apto 502")
    end

    it "is only the street when there is no apartment" do
      expect(build_address.full_address).to eq("Ellauri 1234")
    end
  end

  describe ".valid_full_address?" do
    it "accepts an address the add form would accept" do
      expect(described_class.valid_full_address?("Canelones 892, Apto 3")).to be(true)
    end

    it "rejects a blank address or one without a door number" do
      expect(described_class.valid_full_address?("")).to be(false)
      expect(described_class.valid_full_address?("Otra dirección")).to be(false)
    end
  end
end

# == Schema Information
#
# Table name: delivery_addresses
#
#  id          :bigint           not null, primary key
#  apartment   :string
#  name        :string           not null
#  street      :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint           not null
#
# Indexes
#
#  index_delivery_addresses_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
