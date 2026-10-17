# frozen_string_literal: true

require "rails_helper"

# IBP-037 / IBP-006: los beneficios se aplican vianda por vianda, empezando por las
# más caras y por los beneficios de mayor porcentaje, hasta completar 100% por vianda.
# Los casos de precio/resumen que se comparten con
# app/javascript/pages/consumer/dashboard/pricing.test.ts deben mantenerse en sincronía.
RSpec.describe OrderPricing do
  around do |example|
    travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
  end

  let(:consumer) { consumers(:one) }
  let(:menu) { Menu.create!(provider: providers(:tuviandita), name: "Milanesa", description: "Con puré", price: 300) }
  let(:schedule) { Schedule.create!(menu:, date: Date.new(2026, 9, 16), amount: 20) }
  let(:cheap_menu) { Menu.create!(provider: providers(:tuviandita), name: "Ensalada", description: "Con huevo", price: 100) }
  let(:cheap_schedule) { Schedule.create!(menu: cheap_menu, date: Date.new(2026, 9, 16), amount: 20) }

  before { consumer.benefits.destroy_all }

  def base!(percentage: 50, amount: 20, max_price: nil)
    consumer.benefits.create!(
      benefit_configuration: benefit_configurations(:monthly), percentage:, amount:, max_price:,
      due_date: Date.new(2026, 9, 30)
    )
  end

  def special!(percentage: 30, amount: nil, due_date: nil, max_price: nil,
               configuration: benefit_configurations(:gift), status: :current)
    consumer.benefits.create!(
      benefit_configuration: configuration, description: "Premio", percentage:, amount:, due_date:, max_price:, status:
    )
  end

  def item(on, quantity)
    { schedule: on, quantity: }
  end

  # Cada argumento es un par [schedule, quantity]. Devuelve { schedule_id => OrderItemPricing }.
  def price_cart(*items, modifiable_order: nil)
    described_class.new(consumer.reload, modifiable_order:).call(items.map { |on, quantity| item(on, quantity) })
  end

  def price(quantity, on: schedule, modifiable_order: nil)
    price_cart([ on, quantity ], modifiable_order:)[on.id]
  end

  def place!(quantity, status: :pending)
    line = price(quantity)
    Order.reserve(
      consumer:, schedule:, quantity:, delivery_method: :office, address: nil,
      discounted_price: line.discounted_price, benefits: line.benefits
    ).tap { it.update_columns(status: Order.statuses[status]) }
  end

  describe "#call" do
    describe "return shape" do
      it "returns a hash of OrderItemPricing keyed by schedule id" do
        base!

        result = price_cart([ schedule, 1 ], [ cheap_schedule, 1 ])

        expect(result.keys).to contain_exactly(schedule.id, cheap_schedule.id)
        expect(result.values).to all(be_a(OrderPricing::OrderItemPricing))
      end

      it "charges the full price and applies nothing for an employee without benefits" do
        line = price(1)

        expect(line).to have_attributes(price: 300, discounted_price: 300, benefits: {})
      end
    end

    describe "adding up benefits" do
      it "adds the special subsidy to the base one" do
        base = base!
        special = special!

        line = price(1)

        expect(line).to have_attributes(price: 300, discounted_price: 60)
        expect(line.benefits).to eq([ [ base, 1 ], [ special, 1 ] ].to_h)
      end

      it "adds up two specials at the same time" do
        base!
        special!(percentage: 25, configuration: benefit_configurations(:seniority))
        special!(percentage: 10)

        expect(price(1).discounted_price).to eq(45)
      end

      it "applies the special to an employee without a base benefit" do
        special!

        expect(price(1).discounted_price).to eq(210)
      end

      it "covers only as many meals as the special has uses left" do
        base = base!(amount: 1)
        special = special!(amount: 1)

        line = price(3)

        # 1ª con 80% (60), 2ª y 3ª a precio completo.
        expect(line.discounted_price).to eq(660)
        expect(line.benefits).to eq([ [ base, 1 ], [ special, 1 ] ].to_h)
      end

      it "applies the special once the monthly quota is used up" do
        base!(amount: 1)
        place!(1)
        special = special!

        line = price(2)

        expect(line.discounted_price).to eq(420)
        expect(line.benefits).to eq([ [ special, 2 ] ].to_h)
      end

      it "covers every unit in the order when the special has unlimited uses" do
        special = special!(amount: nil)

        line = price(10)

        expect(line.discounted_price).to eq(2100)
        expect(line.benefits).to eq([ [ special, 10 ] ].to_h)
      end
    end

    describe "the 100% cap per meal" do
      it "caps the sum at 100% and doesn't apply the benefits that are left over" do
        base!
        special = special!(percentage: 100)

        line = price(1)

        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq({ special => 1 })
      end

      it "still applies the benefit that takes the meal past 100%" do
        base = base!(percentage: 50)
        gift = special!(percentage: 40)
        seniority = special!(percentage: 30, configuration: benefit_configurations(:seniority))

        line = price(1)

        # 50% + 40% = 90% todavía no alcanza: el de 30% hace falta aunque se pase.
        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq([ [ base, 1 ], [ gift, 1 ], [ seniority, 1 ] ].to_h)
      end

      it "stops applying benefits as soon as the meal reaches 100%" do
        base = base!(percentage: 60)
        gift = special!(percentage: 40)
        special!(percentage: 25, configuration: benefit_configurations(:seniority))

        line = price(1)

        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq([ [ base, 1 ], [ gift, 1 ] ].to_h)
      end

      it "doesn't spend the uses of the benefits it didn't need" do
        base!(percentage: 60)
        special!(percentage: 40)
        unused = special!(percentage: 25, amount: 3, configuration: benefit_configurations(:seniority))

        place!(1)

        expect(described_class.new(consumer.reload).remaining_uses(unused)).to eq(3)
      end

      it "doesn't waste uses on a meal that is already at 100%" do
        base = base!(percentage: 100, amount: 1)
        special = special!(percentage: 60, amount: 1)

        line = price(2)

        # Una vianda queda gratis con el base; el especial cubre la otra (40% a pagar).
        expect(line.benefits).to eq({ base => 1, special => 1 })
        expect(line.discounted_price).to eq(120)
      end
    end

    describe "most expensive meals first" do
      it "applies a limited benefit to the most expensive meal, whatever the cart order" do
        special = special!(amount: 1)

        result = price_cart([ cheap_schedule, 1 ], [ schedule, 1 ])

        expect(result[schedule.id]).to have_attributes(discounted_price: 210, benefits: { special => 1 })
        expect(result[cheap_schedule.id]).to have_attributes(discounted_price: 100, benefits: {})
      end

      it "spreads the uses over the most expensive units of the whole cart" do
        special = special!(amount: 2)

        result = price_cart([ schedule, 1 ], [ cheap_schedule, 2 ])

        # 1 milanesa (300) y 1 de las 2 ensaladas (100) con 30%: 210 y 70 + 100.
        expect(result[cheap_schedule.id].discounted_price).to eq(170)
        expect(result[schedule.id].discounted_price).to eq(210)
        expect(result[cheap_schedule.id].benefits).to eq({ special => 1 })
      end

      it "doesn't touch the cheap meals while the expensive ones can absorb the uses" do
        special!(amount: 3)

        result = price_cart([ cheap_schedule, 2 ], [ schedule, 3 ])

        expect(result[schedule.id].discounted_price).to eq(630)
        expect(result[cheap_schedule.id].discounted_price).to eq(200)
      end
    end

    describe "best benefits first" do
      it "applies the higher percentages first" do
        base!(percentage: 30)
        gift = special!(percentage: 100)

        line = price(1)

        expect(line.benefits).to eq({ gift => 1 })
        expect(line.discounted_price).to eq(0)
      end

      it "orders the applied benefits from the highest to the lowest percentage" do
        base = base!(percentage: 20)
        gift = special!(percentage: 50)
        seniority = special!(percentage: 10, configuration: benefit_configurations(:seniority))

        expect(price(1).benefits).to eq({ gift => 1, base => 1, seniority => 1 })
      end

      it "gives the best limited benefit to the most expensive meal" do
        base = base!(percentage: 20)
        gift = special!(percentage: 60, amount: 1)

        result = price_cart([ cheap_schedule, 1 ], [ schedule, 1 ])

        expect(result[schedule.id]).to have_attributes(discounted_price: 60, benefits: { gift => 1, base => 1 })
        expect(result[cheap_schedule.id]).to have_attributes(discounted_price: 80, benefits: { base => 1 })
      end
    end

    describe "max_price" do
      it "applies nothing when the price exceeds the max_price of the benefit" do
        special!(max_price: 299)

        expect(price(1)).to have_attributes(discounted_price: 300, benefits: {})
      end

      it "applies the benefit when the price is exactly its max_price" do
        special!(max_price: 300)

        expect(price(1).discounted_price).to eq(210)
      end

      it "also respects the max_price of the base benefit" do
        base!(max_price: 100)

        expect(price(1)).to have_attributes(discounted_price: 300, benefits: {})
      end

      it "skips only the benefit that exceeds its max_price and keeps the others" do
        base = base!
        special!(max_price: 200)

        line = price(1)

        expect(line.discounted_price).to eq(150)
        expect(line.benefits).to eq([ [ base, 1 ] ].to_h)
      end

      it "evaluates the max_price meal by meal" do
        special = special!(max_price: 150)

        result = price_cart([ schedule, 1 ], [ cheap_schedule, 1 ])

        expect(result[schedule.id]).to have_attributes(discounted_price: 300, benefits: {})
        expect(result[cheap_schedule.id]).to have_attributes(discounted_price: 70, benefits: { special => 1 })
      end

      it "doesn't spend a use on a meal the benefit can't cover" do
        special = special!(amount: 1, max_price: 150)

        result = price_cart([ schedule, 1 ], [ cheap_schedule, 1 ])

        # La milanesa se saltea por max_price y el uso queda para la ensalada.
        expect(result[schedule.id].discounted_price).to eq(300)
        expect(result[cheap_schedule.id]).to have_attributes(discounted_price: 70, benefits: { special => 1 })
      end
    end

    describe "validity" do
      it "leaves out an expired special" do
        special!(status: :expired)

        expect(price(1).discounted_price).to eq(300)
      end

      it "leaves out a special whose configuration RRHH deactivated" do
        special!
        benefit_configurations(:gift).update!(deactivated_at: Time.current)
        benefit_configurations(:gift).refresh_benefits

        expect(price(1).discounted_price).to eq(300)
      end

      it "uses the delivery date, not today, to decide if the special still applies" do
        special!(due_date: Date.new(2026, 9, 16))
        later = Schedule.create!(menu:, date: Date.new(2026, 9, 17), amount: 20)

        result = price_cart([ schedule, 1 ], [ later, 1 ])

        expect(result[schedule.id].discounted_price).to eq(210)
        expect(result[later.id].discounted_price).to eq(300)
      end
    end

    describe "with a modifiable order" do
      it "gives back to the modified order the uses it already holds" do
        special = special!(amount: 2)
        order = place!(1)

        line = price(3, modifiable_order: order)

        expect(line.discounted_price).to eq(720)
        expect(line.benefits).to eq({ special => 2 })
      end

      it "doesn't give them back when no order is being modified" do
        special!(amount: 2)
        place!(1)

        expect(price(3).discounted_price).to eq(810)
      end
    end
  end

  describe "#remaining_uses" do
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

    it "counts the uses held by the modifiable order as available" do
      special = special!(amount: 2)
      order = place!(2)

      expect(described_class.new(consumer).remaining_uses(special)).to eq(0)
      expect(described_class.new(consumer, modifiable_order: order).remaining_uses(special)).to eq(2)
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

    it "evaluates expiration against the provided date parameter" do
      base!
      special!(due_date: Date.new(2026, 9, 20))

      expect(described_class.new(consumer).summary(date: Date.new(2026, 9, 19)).specials).to be_present
      expect(described_class.new(consumer).summary(date: Date.new(2026, 9, 21)).specials).to be_empty
    end
  end
end
