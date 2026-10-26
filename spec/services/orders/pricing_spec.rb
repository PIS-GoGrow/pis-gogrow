# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::Pricing do
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

  def item(on, quantity, selected)
    { schedule: on, quantity:, benefits: selected.map { |b| b.id } }
  end

  # Cada argumento es un arreglo [schedule, quantity, [benefit_ids]]
  # Devuelve [schedule_id, OrderItemPricing]
  def price_cart(*items, modifiable_order: nil)
    described_class.new(consumer.reload, modifiable_order:).call(items.map { |on, quantity, selected| item(on, quantity, selected) })
  end

  def price(quantity, on: schedule, modifiable_order: nil, selected: [])
    price_cart([ on, quantity, selected ], modifiable_order:).first.second
  end

  def place!(quantity, status: :pending, selected: [])
    line = price(quantity, selected:)
    Order.reserve(
      consumer:, schedule:, quantity:, delivery_method: :office, address: nil,
      discounted_price: line.discounted_price, benefits: line.benefits
    ).tap { it.update_columns(status: Order.statuses[status]) }
  end

  describe "#call" do
    describe "return shape" do
      it "returns a hash of OrderItemPricing keyed by schedule id" do
        base!

        result = price_cart([ schedule, 1, [] ], [ cheap_schedule, 1, [] ])

        expect(result.map(&:first)).to contain_exactly(schedule.id, cheap_schedule.id)
        expect(result.map(&:second)).to all(be_a(Orders::Pricing::OrderItemPricing))
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

        line = price(1, selected: [ special ])

        expect(line).to have_attributes(price: 300, discounted_price: 60)
        expect(line.benefits).to eq([ [ base, Orders::Pricing::BenefitUsed.new(1, 150) ], [ special, Orders::Pricing::BenefitUsed.new(1, 90) ] ].to_h)
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

        line = price(3, selected: [ special ])

        # 1ª con 80% (60), 2ª y 3ª a precio completo.
        expect(line.discounted_price).to eq(660)
        expect(line.benefits).to eq([ [ base, Orders::Pricing::BenefitUsed.new(1, 150) ], [ special, Orders::Pricing::BenefitUsed.new(1, 90) ] ].to_h)
      end

      it "applies the special once the monthly quota is used up" do
        base!(amount: 1)
        place!(1)
        special = special!

        line = price(2)

        expect(line.discounted_price).to eq(420)
        expect(line.benefits).to eq([ [ special, Orders::Pricing::BenefitUsed.new(2, 180) ] ].to_h)
      end

      it "covers every unit in the order when the special has unlimited uses" do
        special = special!(amount: nil)

        line = price(10)

        expect(line.discounted_price).to eq(2100)
        expect(line.benefits).to eq([ [ special, Orders::Pricing::BenefitUsed.new(10, 900) ] ].to_h)
      end
    end

    describe "the 100% cap per meal" do
      it "caps the sum at 100% and doesn't apply the benefits that are left over" do
        base = base!
        special = special!(percentage: 100)

        line = price(1, selected: [ special ])

        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq({ base => Orders::Pricing::BenefitUsed.new(1, 150), special => Orders::Pricing::BenefitUsed.new(1, 150) })
      end

      it "still applies the benefit that takes the meal past 100%" do
        base = base!(percentage: 50)
        gift = special!(percentage: 40, amount: 1)
        seniority = special!(percentage: 30, configuration: benefit_configurations(:seniority))

        line = price(1, selected: [ gift ])

        # 50% + 30% = 80% todavía no alcanza: el de 40% hace falta aunque se pase.
        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq([ [ base, Orders::Pricing::BenefitUsed.new(1, 150) ], [ gift, Orders::Pricing::BenefitUsed.new(1, 60) ], [ seniority, Orders::Pricing::BenefitUsed.new(1, 90) ] ].to_h)
      end

      it "stops applying benefits as soon as the meal reaches 100%" do
        base = base!(percentage: 60)
        gift = special!(percentage: 40)
        gift2 = special!(percentage: 25, configuration: benefit_configurations(:gift2))

        line = price(1, selected: [ gift, gift2 ])

        expect(line.discounted_price).to eq(0)
        expect(line.benefits).to eq([ [ base, Orders::Pricing::BenefitUsed.new(1, 180) ], [ gift, Orders::Pricing::BenefitUsed.new(1, 120) ] ].to_h)
      end

      it "doesn't spend the uses of the benefits it didn't need" do
        base!(percentage: 60)
        special = special!(percentage: 40, amount: 1)
        unused = special!(percentage: 25, amount: 3, configuration: benefit_configurations(:gift2))

        place!(1, selected: [ special, unused ])

        expect(described_class.new(consumer.reload).remaining_uses(special)).to eq(0)
        expect(described_class.new(consumer.reload).remaining_uses(unused)).to eq(3)
      end

      it "doesn't waste uses on a meal that is already at 100%" do
        base = base!(percentage: 100, amount: 1)
        special = special!(percentage: 60, amount: 1)

        line = price(2, selected: [ special ])

        # Una vianda queda gratis con el base; el especial cubre la otra (40% a pagar).
        expect(line.benefits).to eq({ base => Orders::Pricing::BenefitUsed.new(1, 300), special => Orders::Pricing::BenefitUsed.new(1, 180) })
        expect(line.discounted_price).to eq(120)
      end

      it "applies multiple benefits on a complex order" do
        base = base!(percentage: 50, amount: 3)
        special = special!(percentage: 30, amount: 2)
        special2 = special!(percentage: 25, amount: 7, configuration: benefit_configurations(:gift2))
        seniority = special!(percentage: 30, configuration: benefit_configurations(:seniority))

        pricing = price_cart(
          [ schedule, 6, [special, special2] ],
          [ cheap_schedule, 2, [special2] ],
          [ schedule, 1, [special] ]
        )
        expect(pricing.first.second.discounted_price).to eq(225)
        expect(pricing.first.second.benefits).to eq({
          base => Orders::Pricing::BenefitUsed.new(3, 450),
          special => Orders::Pricing::BenefitUsed.new(2, 180),
          special2 => Orders::Pricing::BenefitUsed.new(6, 405),
          seniority => Orders::Pricing::BenefitUsed.new(6, 540)
        })
        expect(pricing.second.second.discounted_price).to eq(115)
        expect(pricing.second.second.benefits).to eq({
          special2 => Orders::Pricing::BenefitUsed.new(1, 25),
          seniority => Orders::Pricing::BenefitUsed.new(2, 60)
        })
        expect(pricing.third.second.discounted_price).to eq(210)
        expect(pricing.third.second.benefits).to eq({
          seniority => Orders::Pricing::BenefitUsed.new(1, 90)
        })
      end
    end

    describe "selection" do
      it "respects user-selected benefits" do
        base!
        special = special!(percentage: 20, amount: 1)
        unused = special!(percentage: 20, amount: 2, configuration: benefit_configurations(:gift2))

        place!(1, selected: [ special ])

        expect(described_class.new(consumer.reload).remaining_uses(special)).to eq(0)
        expect(described_class.new(consumer.reload).remaining_uses(unused)).to eq(2)
      end

      it "respects user-selected benefits, but applies unlimited benefits anyway" do
        base!
        special = special!(percentage: 20, amount: 1)
        used = special!(percentage: 20, amount: nil, configuration: benefit_configurations(:gift2))

        line = price(1, selected: [ special ])

        expect(line.discounted_price).to eq(30)
      end
    end

    describe "applies benefits to first meals" do
      it "applies a limited benefit to the first meal" do
        special = special!(amount: 1)

        result = price_cart([ cheap_schedule, 1, [ special ] ], [ schedule, 1, [ special ] ])

        expect(result.first.second).to have_attributes(discounted_price: 70, benefits: { special => Orders::Pricing::BenefitUsed.new(1, 30) })
        expect(result.second.second).to have_attributes(discounted_price: 300, benefits: {})
      end

      it "spreads the uses over the first units" do
        special = special!(amount: 2)

        result = price_cart([ schedule, 1, [ special ] ], [ cheap_schedule, 2, [ special ] ])

        # 1 milanesa (300) y 1 de las 2 ensaladas (100) con 30%: 210 y 70 + 100.
        expect(result.second.second.discounted_price).to eq(170)
        expect(result.first.second.discounted_price).to eq(210)
        expect(result.second.second.benefits).to eq([ [ special, Orders::Pricing::BenefitUsed.new(1, 30) ] ].to_h)
      end
    end

    describe "best benefits first" do
      it "applies the base benefit first" do
        base = base!(percentage: 30)
        gift = special!(percentage: 100)

        line = price(1, selected: [ gift ])

        expect(line.benefits).to eq({ base => Orders::Pricing::BenefitUsed.new(1, 90), gift => Orders::Pricing::BenefitUsed.new(1, 210) })
        expect(line.discounted_price).to eq(0)
      end

      it "orders the applied benefits from the highest to the lowest percentage" do
        base = base!(percentage: 20)
        gift = special!(percentage: 50)
        seniority = special!(percentage: 10, configuration: benefit_configurations(:seniority))

        expect(price(1).benefits).to eq({ gift => Orders::Pricing::BenefitUsed.new(1, 150), base => Orders::Pricing::BenefitUsed.new(1, 60), seniority => Orders::Pricing::BenefitUsed.new(1, 30) })
      end

      it "gives the best limited benefit to the first occurring meal" do
        base = base!(percentage: 20)
        gift = special!(percentage: 60, amount: 1)

        result = price_cart([ cheap_schedule, 1, [ gift ] ], [ schedule, 1, [ gift ] ])

        expect(result.first.second).to have_attributes(discounted_price: 20, benefits: { gift => Orders::Pricing::BenefitUsed.new(1, 60), base => Orders::Pricing::BenefitUsed.new(1, 20) })
        expect(result.second.second).to have_attributes(discounted_price: 240, benefits: { base => Orders::Pricing::BenefitUsed.new(1, 60) })
      end
    end

    describe "max_price" do
      it "applies nothing when the price exceeds the max_price of the benefit" do
        special = special!(max_price: 299)

        expect(price(1, selected: [ special ])).to have_attributes(discounted_price: 300, benefits: {})
      end

      it "applies the benefit when the price is exactly its max_price" do
        special = special!(max_price: 300)

        expect(price(1, selected: [ special ]).discounted_price).to eq(210)
      end

      it "also respects the max_price of the base benefit" do
        base!(max_price: 100)

        expect(price(1)).to have_attributes(discounted_price: 300, benefits: {})
      end

      it "skips only the benefit that exceeds its max_price and keeps the others" do
        base = base!
        special = special!(max_price: 200)

        line = price(1, selected: [ special ])

        expect(line.discounted_price).to eq(150)
        expect(line.benefits).to eq([ [ base, Orders::Pricing::BenefitUsed.new(1, 150) ] ].to_h)
      end

      it "evaluates the max_price meal by meal" do
        special = special!(max_price: 150)

        result = price_cart([ schedule, 1, [ special ] ], [ cheap_schedule, 1, [ special ] ])

        expect(result.first.second).to have_attributes(discounted_price: 300, benefits: {})
        expect(result.second.second).to have_attributes(discounted_price: 70, benefits: { special => Orders::Pricing::BenefitUsed.new(1, 30) })
      end

      it "doesn't spend a use on a meal the benefit can't cover" do
        special = special!(amount: 1, max_price: 150)

        result = price_cart([ schedule, 1, [ special ] ], [ cheap_schedule, 1, [ special ] ])

        # La milanesa se saltea por max_price y el uso queda para la ensalada.
        expect(result.first.second.discounted_price).to eq(300)
        expect(result.second.second).to have_attributes(discounted_price: 70, benefits: { special => Orders::Pricing::BenefitUsed.new(1, 30) })
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

        result = price_cart([ schedule, 1, [] ], [ later, 1, [] ])

        expect(result.first.second.discounted_price).to eq(210)
        expect(result.second.second.discounted_price).to eq(300)
      end
    end

    describe "with a modifiable order" do
      it "gives back to the modified order the uses it already holds" do
        special = special!(amount: 2)
        order = place!(1, selected: [ special ])

        line = price(3, selected: [ special ], modifiable_order: order)

        expect(line.discounted_price).to eq(720)
        expect(line.benefits).to eq({ special => Orders::Pricing::BenefitUsed.new(2, 180) })
      end

      it "doesn't give them back when no order is being modified" do
        special = special!(amount: 2)
        place!(1, selected: [ special ])

        expect(price(3, selected: [ special ]).discounted_price).to eq(810)
      end
    end
  end

  describe "#remaining_uses" do
    it "counts pending and confirmed orders" do
      special = special!(amount: 2)
      place!(1, selected: [ special ], status: :pending)
      place!(1, selected: [ special ], status: :confirmed)

      expect(described_class.new(consumer).remaining_uses(special)).to eq(0)
      expect(price(1).discounted_price).to eq(300)
    end

    it "gives back the uses of cancelled and rejected orders" do
      special = special!(amount: 2)
      place!(1, selected: [ special ], status: :cancelled)
      place!(1, selected: [ special ], status: :rejected)

      expect(described_class.new(consumer).remaining_uses(special)).to eq(2)
    end

    it "reports unlimited uses as nil" do
      special = special!

      expect(described_class.new(consumer).remaining_uses(special)).to be_nil
    end

    it "counts the uses held by the modifiable order as available" do
      special = special!(amount: 2)
      order = place!(2, selected: [ special ])

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
      special = special!(amount: 1)
      place!(1, selected: [ special ])
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
