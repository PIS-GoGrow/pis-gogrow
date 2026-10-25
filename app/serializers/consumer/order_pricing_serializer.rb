class Consumer::OrderPricingSerializer
  def initialize(items, pricings)
    @items = items
    @pricings = pricings
  end

  def as_json(*)
    {
      subtotal: lines.sum { |l| l[:subtotal] },
      discount: lines.sum { |l| l[:discount] },
      total: lines.sum { |l| l[:total] },
      lines: lines,
      subsidizedQuantity: subsidized_quantities.sum,
      fullPriceQuantity: @items.zip(subsidized_quantities).sum { |item, subsidized| item[:quantity] - subsidized }
    }
  end

  private

  def lines
    @lines ||= @items.zip(@pricings).map { |item, pricing| line_for(item, pricing[1]) }
  end

  def subsidized_quantities
    @subsidized_quantities ||= @pricings.map { |pricing| pricing[1].benefits.sum { |_, units| units } }
  end

  def line_for(item, result)
    quantity = item[:quantity]
    price = result.price.to_f
    discount = price - result.discounted_price.to_f

    {
      subtotal: price,
      discount: discount,
      total: price - discount,
      tiers: tiers_for(result, price, quantity)
    }
  end

  def tiers_for(result, price, quantity)
    result.benefits.map do |benefit, units_used|
      {
        id: benefit.id,
        name: benefit.benefit_configuration.name,
        percentage: benefit.percentage,
        quantity: units_used,
        discount: (price * units_used * benefit.percentage / 100 / quantity).to_f
      }
    end
  end
end
