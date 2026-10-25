# frozen_string_literal: true

class Consumer::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:consumer) }

  private

  def dish_data(schedule)
    menu = schedule.menu

    {
      id: schedule.id,
      date: schedule.date.iso8601,
      remaining: schedule.remaining_amount,
      sold_out: schedule.remaining_amount.zero? || !schedule.available,
      orders_closed: schedule.order_deadline_passed?,
      menu: {
        id: menu.id,
        name: menu.name,
        description: menu.description,
        price: menu.price.to_f,
        option_groups: menu.option_groups.map do |group|
          { id: group.id, name: group.name, options: group.options, limit: group.limit, required: group.required }
        end,
        provider_name: menu.provider_name,
        home_delivery: menu.provider.home_delivery?,
        reviews: menu.reviews.first(4).map do |review|
          {
            id: review.id,
            description: review.description,
            rating: review.rating,
            created_at: review.created_at.to_date.iso8601
          }
        end
      }
    }
  end
end
