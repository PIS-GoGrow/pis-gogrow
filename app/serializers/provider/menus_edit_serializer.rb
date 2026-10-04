# frozen_string_literal: true

class Provider::MenusEditSerializer < ApplicationSerializer
  has_one :menu, resource: MenuSerializer

  typelize saved_menu_id: :number, schedule_date: [ :string, nullable: true ], today: :string, maximum_publish_date: :string,
           agenda: "{ mode: 'none' | 'single' | 'weekly' | 'range'; weekdays: number[]; date: string | null; starts_on: string | null; ends_on: string | null; amount: number | null }",
           scheduled_days: "{ date: string; confirmed_orders: number }[]"
  attributes :saved_menu_id, :schedule_date, :today, :maximum_publish_date, :agenda, :scheduled_days
end
