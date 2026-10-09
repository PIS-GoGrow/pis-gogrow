# frozen_string_literal: true

require "rails_helper"

# IBP-037 / IBP-006: los subsidios especiales se suman al base, vianda por
# vianda. Los mismos casos están en app/javascript/pages/consumer/dashboard/pricing.test.ts.
RSpec.describe OrderPricing do
  around do |example|
    travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
  end

  let(:consumer) { consumers(:one) }
  let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa", description: "Con puré", price: 300) }
  let(:schedule) { Schedule.create!(menu:, date: Date.new(2026, 9, 16), amount: 20) }

  before { consumer.benefits.destroy_all }

  def base!(percentage: 50, amount: 20)
    consumer.benefits.create!(
      benefit_configuration: benefit_configurations(:monthly), percentage:, amount:, due_date: Date.new(2026, 9, 30)
    )
  end

  def special!(percentage: 30, amount: nil, due_date: nil, configuration: benefit_configurations(:gift), status: :current)
    consumer.benefits.create!(
      benefit_configuration: configuration, description: "Premio", percentage:, amount:, due_date:, status:
    )
  end

  def price(quantity, on: schedule, held_by: nil)
    described_class.new(consumer.reload, held_by:).call([ { schedule: on, quantity: } ]).first
  end

  def place!(quantity, status: :pending)
    line = price(quantity)
    Order.reserve(
      consumer:, schedule:, quantity:, delivery_method: :office, address: nil,
      discounted_price: line.discounted_price, benefits: line.benefits
    ).tap { it.update_columns(status: Order.statuses[status]) }
  end

  it "adds the special subsidy to the base one" do
    base = base!
    special = special!

    line = price(1)

    expect(line).to have_attributes(price: 300, discounted_price: 60)
    expect(line.benefits).to eq(base => 1, special => 1)
  end

  it "caps the sum at 100%" do
    base!
    special!(percentage: 100)

    expect(price(1).discounted_price).to eq(0)
  end

  it "adds up two specials at the same time" do
    base!
    special!(percentage: 25, configuration: benefit_configurations(:seniority))
    special!(percentage: 10)

    expect(price(1).discounted_price).to eq(45)
  end

  it "covers only as many meals as the special has uses left" do
    base = base!(amount: 1)
    special = special!(amount: 1)

    line = price(3)

    # 1ª con 80% (60), 2ª y 3ª a precio completo.
    expect(line.discounted_price).to eq(660)
    expect(line.benefits).to eq(base => 1, special => 1)
  end

  it "applies the special once the monthly quota is used up" do
    base!(amount: 1)
    place!(1)
    special = special!

    line = price(2)

    expect(line.discounted_price).to eq(420)
    expect(line.benefits).to eq(special => 2)
  end

  it "applies the special to an employee without a base benefit" do
    special!

    expect(price(1).discounted_price).to eq(210)
  end

  it "spends the special uses on the first items of the cart" do
    special!(amount: 1)
    other = Schedule.create!(menu:, date: Date.new(2026, 9, 17), amount: 20)

    lines = described_class.new(consumer).call([ { schedule:, quantity: 1 }, { schedule: other, quantity: 1 } ])

    expect(lines.map(&:discounted_price)).to eq([ 210, 300 ])
  end

  describe "validity" do
    it "leaves out an expired special" do
      special!(status: :expired)

      expect(price(1).discounted_price).to eq(300)
    end

    it "leaves out a special whose configuration RRHH deactivated" do
      special!
      benefit_configurations(:gift).update!(deactivated_at: Time.current)

      expect(price(1).discounted_price).to eq(300)
    end

    it "uses the delivery date, not today, to decide if the special still applies" do
      special!(due_date: Date.new(2026, 9, 16))
      later = Schedule.create!(menu:, date: Date.new(2026, 9, 17), amount: 20)

      expect(price(1).discounted_price).to eq(210)
      expect(price(1, on: later).discounted_price).to eq(300)
    end
  end

  describe "uses already spent" do
    it "counts pending and confirmed orders" do
      special = special!(amount: 2)
      place!(1, status: :pending)
      place!(1, status: :confirmed)

      expect(described_class.new(consumer).remaining_uses(special)).to eq(0)
      expect(price(1).discounted_price).to eq(300)
    end

    it "gives back the uses of cancelled and rejected orders" do
      special = special!(amount: 2)
      place!(1, status: :cancelled)
      place!(1, status: :rejected)

      expect(described_class.new(consumer).remaining_uses(special)).to eq(2)
    end

    it "reports unlimited uses as nil" do
      special = special!

      expect(described_class.new(consumer).remaining_uses(special)).to be_nil
    end

    it "gives back to a modified order the uses it already holds" do
      special = special!(amount: 2)
      order = place!(1)

      line = price(3, held_by: order)

      expect(line.discounted_price).to eq(720)
      expect(line.benefits).to eq(special => 2)
    end
  end

  describe "#summary" do
    it "adds the base and the specials in force, capped at 100%" do
      base!
      special!(percentage: 25, configuration: benefit_configurations(:seniority))

      expect(described_class.new(consumer).summary).to have_attributes(
        total: 75, base: 50, specials: [ { name: "Premio", percentage: 25 } ]
      )

      special!(percentage: 40)
      expect(described_class.new(consumer.reload).summary.total).to eq(100)
    end

    it "leaves out specials that already expired or have no uses left" do
      base!
      special!(amount: 1)
      place!(1)
      special!(due_date: Date.new(2026, 9, 13), configuration: benefit_configurations(:seniority))

      expect(described_class.new(consumer.reload).summary).to have_attributes(total: 50, specials: [])
    end

    it "is nil for an employee without any benefit" do
      expect(described_class.new(consumer).summary).to be_nil
    end
  end
end
