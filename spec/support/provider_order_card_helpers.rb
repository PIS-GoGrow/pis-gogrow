# frozen_string_literal: true

# La tarjeta del pedido no muestra ningún código: se la ubica por su link al detalle.
module ProviderOrderCardHelpers
  def provider_order_card(order)
    "[data-slot='card']:has(a[href='#{provider_order_path(order)}'])"
  end
end

RSpec.configure do |config|
  config.include ProviderOrderCardHelpers, type: :system
end
