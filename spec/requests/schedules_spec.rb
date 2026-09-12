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

    it "does not publish menus belonging to another provider" do
      user = users(:one)
      provider = Provider.create!(user: user)

      own_menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      other_user = users(:two)
      other_provider = Provider.create!(user: other_user)

      foreign_menu = other_provider.menus.create!(
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
            { menu_id: own_menu.id, amount: 20 },
            { menu_id: foreign_menu.id, amount: 15 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not publish a menu with zero initial stock" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current + 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 0 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "does not publish a menu with negative initial stock" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current + 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: -5 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "does not publish the same menu twice for the same date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current + 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 },
            { menu_id: menu.id, amount: 67 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "does not add menus to an already published date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      first_menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      second_menu = provider.menus.create!(
        name: "Ravioles",
        description: "Ravioles con salsa",
        price: 400
      )

      date = Date.current + 1.day

      first_menu.schedules.create!(
        date: date,
        amount: 20
      )

      sign_in(user)

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: second_menu.id, amount: 15 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "does not publish a menu for a past date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current - 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "publishes a menu for today" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.to change(Schedule, :count).by(1)

      expect(Schedule.find_by!(menu: menu, date: date).amount).to eq(20)
    end

    #-------------------------------------------------------------------------#
    # Estos son los specs importantes (el proveedor puede publicar hasta 1 semana después de la actual)
    
    it "does not publish beyond the end of next week" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      end_of_next_week = Date.current.end_of_week(:monday) + 1.week
      date = end_of_next_week + 1.day

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.not_to change(Schedule, :count)
    end

    it "publishes a menu on the last allowed date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in(user)

      date = Date.current.end_of_week(:monday) + 1.week

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.to change(Schedule, :count).by(1)

      expect(Schedule.find_by!(menu: menu, date: date).amount).to eq(20)
    end

    #-------------------------------------------------------------------------#

    it "allows different providers to publish menus for the same date" do
      first_user = users(:one)
      first_provider = Provider.create!(user: first_user)

      first_menu = first_provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      second_user = users(:two)
      second_provider = Provider.create!(user: second_user)

      second_menu = second_provider.menus.create!(
        name: "Ravioles",
        description: "Ravioles con salsa",
        price: 400
      )

      date = Date.current + 1.day

      first_menu.schedules.create!(
        date: date,
        amount: 20
      )

      sign_in(second_user)

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: second_menu.id, amount: 15 }
          ]
        }
      end.to change(Schedule, :count).by(1)

      expect(
        Schedule.find_by!(menu: second_menu, date: date).amount
      ).to eq(15)
    end

    it "does not allow a non-provider user to publish schedules" do
      user = users(:one)
      sign_in(user)

      expect do
        post schedules_path, params: {
          date: Date.current.to_s,
          items: [
            { menu_id: 999, amount: 20 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to have_http_status(:redirect)
    end

  end

  
end
