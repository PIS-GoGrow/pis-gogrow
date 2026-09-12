# frozen_string_literal: true

require "rails_helper"



RSpec.describe "Schedules", type: :request do
  fixtures :users

  describe "POST /schedules" do
    it "publishes multiple menus for the selected date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      first_menu = provider.menus.create!(
        name: "Milanesa con puré",
        description: "Milanesa acompañada de puré",
        price: 350
      )

      second_menu = provider.menus.create!(
        name: "Ravioles",
        description: "Ravioles con salsa",
        price: 400
      )

      sign_in(user)

      date = Date.current + 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            {
              menu_id: first_menu.id,
              amount: 20
            },
            {
              menu_id: second_menu.id,
              amount: 15
            }
          ]
        }
      end.to change(Schedule, :count).by(2)

      first_schedule = Schedule.find_by!(
        menu: first_menu,
        date: date
      )

      second_schedule = Schedule.find_by!(
        menu: second_menu,
        date: date
      )

      expect(first_schedule.amount).to eq(20)
      expect(second_schedule.amount).to eq(15)
    end
  end
end
