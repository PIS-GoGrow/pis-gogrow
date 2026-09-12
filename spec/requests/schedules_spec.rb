# frozen_string_literal: true

require "rails_helper"



RSpec.describe "Schedules", type: :request do
  fixtures :users

  def inertia_page
    document = Nokogiri::HTML(response.body)
    JSON.parse(document.at_css('script[data-page="app"]').text)
  end

  describe "GET /schedules" do
    it "returns the current week for the provider" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      get schedules_path

      expect(response).to have_http_status(:ok)

      expect(response.body).to include("schedules/index")
      expect(response.body).to include(
        Date.current.beginning_of_week(:monday).to_s
      )
      expect(response.body).to include(
        Date.current.end_of_week(:monday).to_s
      )
    end

    it "returns the requested week" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      week_start = Date.current.beginning_of_week(:monday) - 1.week
      week_end = week_start.end_of_week(:monday)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(week_start.to_s)
      expect(response.body).to include(week_end.to_s)
    end

    it "returns the seven days of the requested week" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      week_start = Date.current.beginning_of_week(:monday) - 1.week

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)

      page = inertia_page
      days = page.dig("props", "days")

      expect(days.map { |day| day["date"] }).to eq(
        (week_start..week_start + 6.days).map(&:to_s)
      )
    end

    it "marks a day as published when the provider has schedules for that date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      week_start = Date.current.beginning_of_week(:monday)
      published_date = week_start + 2.days

      menu.schedules.create!(
        date: published_date,
        amount: 20
      )

      sign_in(user)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)

      days = inertia_page.dig("props", "days")

      published_day = days.find { |day| day["date"] == published_date.to_s }
      unpublished_day = days.find { |day| day["date"] == (week_start + 3.days).to_s }

      expect(published_day["published"]).to be(true)
      expect(unpublished_day["published"]).to be(false)
    end

    it "marks only unpublished allowed dates as publishable" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      week_start = Date.current.next_week(:monday)
      published_date = week_start + 1.day
      available_date = week_start + 2.days

      menu.schedules.create!(
        date: published_date,
        amount: 20
      )

      sign_in(user)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      days = inertia_page.dig("props", "days")

      published_day =
        days.find { |day| day["date"] == published_date.to_s }

      available_day =
        days.find { |day| day["date"] == available_date.to_s }

      expect(published_day["publishable"]).to be(false)
      expect(available_day["publishable"]).to be(true)
    end

    it "marks past dates as not publishable" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      week_start = Date.current.beginning_of_week(:monday) - 1.week

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      days = inertia_page.dig("props", "days")

      expect(days).to all(
        satisfy { |day| day["publishable"] == false }
      )
    end

    it "marks the last allowed date as publishable" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      last_allowed_date =
        Date.current.end_of_week(:monday) + 1.week

      week_start =
        last_allowed_date.beginning_of_week(:monday)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      days = inertia_page.dig("props", "days")

      day =
        days.find do |current_day|
          current_day["date"] == last_allowed_date.to_s
        end

      expect(day["publishable"]).to be(true)
    end


    it "returns the schedules published for each day" do
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

      week_start = Date.current.beginning_of_week(:monday)
      published_date = week_start + 2.days

      first_schedule = first_menu.schedules.create!(
        date: published_date,
        amount: 20
      )

      second_schedule = second_menu.schedules.create!(
        date: published_date,
        amount: 15
      )

      sign_in(user)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      days = inertia_page.dig("props", "days")

      published_day =
        days.find { |day| day["date"] == published_date.to_s }

      expect(published_day["schedules"]).to contain_exactly(
        {
          "id" => first_schedule.id,
          "menu_id" => first_menu.id,
          "amount" => 20
        },
        {
          "id" => second_schedule.id,
          "menu_id" => second_menu.id,
          "amount" => 15
        }
      )
    end

    it "returns only the menus belonging to the provider" do
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

      other_user = users(:two)
      other_provider = Provider.create!(user: other_user)

      foreign_menu = other_provider.menus.create!(
        name: "Ensalada",
        description: "Ensalada completa",
        price: 300
      )

      sign_in(user)

      get schedules_path

      expect(response).to have_http_status(:ok)

      menus = inertia_page.dig("props", "menus")

      expect(menus.map { |menu| menu["id"] }).to contain_exactly(
        first_menu.id,
        second_menu.id
      )

      expect(menus.map { |menu| menu["id"] }).not_to include(foreign_menu.id)
    end

    it "does not navigate beyond next week" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      requested_week =
        Date.current.beginning_of_week(:monday) + 2.weeks

      maximum_week =
        Date.current.beginning_of_week(:monday) + 1.week

      get schedules_path, params: {
        week_start: requested_week.to_s
      }

      expect(response).to redirect_to(
        schedules_path(week_start: maximum_week.to_s)
      )
    end

    it "redirects to the current week when week_start is invalid" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in(user)

      get schedules_path, params: {
        week_start: "banana"
      }

      expect(response).to redirect_to(schedules_path)
    end
  end

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
