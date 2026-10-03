# frozen_string_literal: true

require "rails_helper"

def next_publishable_date
  date = Date.current + 1.day
  date += 1.day until date.on_weekday?
  date
end

RSpec.describe "Schedules", type: :request do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers

  def sign_in_with_role(user, role:)
    session = user.sessions.create!(role: role)
    cookies[:session_token] =
      AuthenticationHelpers.signed_cookie(:session_token, session.id)
  end

  def inertia_page
    document = Nokogiri::HTML(response.body)
    JSON.parse(document.at_css('script[data-page="app"]').text)
  end

  describe "GET /schedules" do
    it "returns the current week for the provider" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in_with_role(user, role: :provider)

      get schedules_path

      expect(response).to have_http_status(:ok)

      page = inertia_page

      expect(page["component"]).to eq("schedules/index")

      expect(page.dig("props", "week", "starts_on")).to eq(
        Date.current.beginning_of_week(:monday).to_s
      )

      expect(page.dig("props", "week", "ends_on")).to eq(
        (Date.current.beginning_of_week(:monday) + 4.days).to_s
      )
    end

    it "returns the requested week" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in_with_role(user, role: :provider)

      week_start = Date.current.beginning_of_week(:monday) - 1.week
      week_end = week_start + 4.days

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(week_start.to_s)
      expect(response.body).to include(week_end.to_s)
    end

    it "returns the five weekdays of the requested week" do
      user = users(:one)
      Provider.create!(user: user)

      sign_in_with_role(user, role: :provider)

      week_start = Date.current.beginning_of_week(:monday) - 1.week

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)

      page = inertia_page
      days = page.dig("props", "days")

      expect(days.map { |day| day["date"] }).to eq(
        (week_start..week_start + 4.days).map(&:to_s)
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

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

      last_allowed_date =
        Date.current.next_week(:monday) + 4.days

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

      sign_in_with_role(user, role: :provider)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      days = inertia_page.dig("props", "days")

      published_day =
        days.find { |day| day["date"] == published_date.to_s }

      expect(published_day["schedules"]).to contain_exactly(
        a_hash_including(
          "id" => first_schedule.id,
          "menu_id" => first_menu.id,
          "amount" => 20,
          "menu" => a_hash_including(
            "id" => first_menu.id,
            "name" => "Milanesa"
          )
        ),
        a_hash_including(
          "id" => second_schedule.id,
          "menu_id" => second_menu.id,
          "amount" => 15,
          "menu" => a_hash_including(
            "id" => second_menu.id,
            "name" => "Ravioles"
          )
        )
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

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

      get schedules_path, params: {
        week_start: "banana"
      }

      expect(response).to redirect_to(schedules_path)
    end

    it "marks future and today published schedules as editable" do
      user = users(:one)
      provider = Provider.create!(user: user)
      menu = provider.menus.create!(name: "Milanesa", description: "Rica milanesa", price: 350)

      travel_to(Date.current.beginning_of_week(:monday) + 1.day) do
        today_date = Date.current
        future_date = Date.current + 2.days

        menu.schedules.create!(date: today_date, amount: 10)
        menu.schedules.create!(date: future_date, amount: 15)

        sign_in_with_role(user, role: :provider)

        get schedules_path, params: {
          week_start: Date.current.beginning_of_week(:monday).to_s
        }

        expect(response).to have_http_status(:ok)
        days = inertia_page.dig("props", "days")

        today_day = days.find { |d| d["date"] == today_date.to_s }
        future_day = days.find { |d| d["date"] == future_date.to_s }

        expect(today_day["editable"]).to be(true)
        expect(future_day["editable"]).to be(true)
      end
    end

    it "marks past published schedules as not editable" do
      user = users(:one)
      provider = Provider.create!(user: user)
      menu = provider.menus.create!(name: "Milanesa", description: "Rica milanesa", price: 350)

      week_start = Date.current.beginning_of_week(:monday) - 1.week
      past_date = week_start + 1.day

      menu.schedules.create!(date: past_date, amount: 10)

      sign_in_with_role(user, role: :provider)

      get schedules_path, params: {
        week_start: week_start.to_s
      }

      expect(response).to have_http_status(:ok)
      days = inertia_page.dig("props", "days")

      past_day = days.find { |d| d["date"] == past_date.to_s }
      expect(past_day["editable"]).to be(false)
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

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

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

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

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

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: 0 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to redirect_to(schedules_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] }
      )
    end

    it "does not publish a menu with negative initial stock" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: -5 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to redirect_to(schedules_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] }
      )
    end

    it "does not publish a menu with stock greater than the integer limit" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: Schedule::MAX_AMOUNT + 1 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to redirect_to(schedules_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] }
      )
    end

    it "publishes a menu with stock equal to the maximum allowed" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: Schedule::MAX_AMOUNT }
          ]
        }
      end.to change(Schedule, :count).by(1)

      schedule = Schedule.find_by!(menu: menu, date: date)
      expect(schedule.amount).to eq(Schedule::MAX_AMOUNT)
      expect(response).to redirect_to(schedules_path(week_start: date.beginning_of_week(:monday).to_s))
    end

    it "does not publish any menu when at least one item exceeds the maximum allowed stock" do
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

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: first_menu.id, amount: 20 },
            { menu_id: second_menu.id, amount: Schedule::MAX_AMOUNT + 1 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to redirect_to(schedules_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] }
      )
    end

    it "does not publish a menu with non-integer stock" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

      expect do
        post schedules_path, params: {
          date: date.to_s,
          items: [
            { menu_id: menu.id, amount: "10.5" }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to redirect_to(schedules_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] }
      )
    end
    it "does not publish the same menu twice for the same date" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      date = next_publishable_date

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

      date = next_publishable_date

      first_menu.schedules.create!(
        date: date,
        amount: 20
      )

      sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

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
      travel_to(Date.current.beginning_of_week(:monday)) do
        user = users(:one)
        provider = Provider.create!(user: user)

        menu = provider.menus.create!(
          name: "Milanesa",
          description: "Milanesa con puré",
          price: 350
        )

        sign_in_with_role(user, role: :provider)

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

      sign_in_with_role(user, role: :provider)

      end_of_next_week = Date.current.next_week(:monday) + 4.days
      date = Date.current.next_week(:monday) + 1.week

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

      sign_in_with_role(user, role: :provider)

      date = Date.current.next_week(:monday) + 4.days

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

      date = next_publishable_date

      first_menu.schedules.create!(
        date: date,
        amount: 20
      )

      sign_in_with_role(second_user, role: :provider)

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
      company = Company.create!(
        name: "Empresa de prueba",
        address: "Dirección de prueba"
      )

      Consumer.create!(
        user: user,
        company: company
      )

      sign_in_with_role(user, role: :consumer)

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

    it "does not publish a menu on Saturday" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      saturday = Date.current.next_week(:monday) + 5.days

      expect do
        post schedules_path, params: {
          date: saturday.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to have_http_status(:redirect)
    end

    it "does not publish a menu on Sunday" do
      user = users(:one)
      provider = Provider.create!(user: user)

      menu = provider.menus.create!(
        name: "Milanesa",
        description: "Milanesa con puré",
        price: 350
      )

      sign_in_with_role(user, role: :provider)

      sunday = Date.current.next_week(:monday) + 6.days

      expect do
        post schedules_path, params: {
          date: sunday.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }
      end.not_to change(Schedule, :count)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /schedules/update_by_date" do
    let(:provider_user) { users(:provider_user) }
    let(:provider) { providers(:tuviandita) }
    let(:menu) { menus(:milanesa) }
    let(:target_date) { Date.current.next_week(:thursday) }

    before { Schedule.where(date: target_date).destroy_all }

    context "control de acceso por rol" do
      it "redirige a iniciar sesión si el visitante no tiene sesión" do
        patch update_by_date_schedules_path, params: {
          date: (Date.current + 2.days).to_s,
          items: [ { menu_id: menu.id, amount: 10 } ]
        }

        expect(response).to redirect_to(sign_in_path)
      end

      it "bloquea a usuarios con rol consumer" do
        sign_in(users(:one), role: :consumer)

        patch update_by_date_schedules_path, params: {
          date: (Date.current + 2.days).to_s,
          items: [ { menu_id: menu.id, amount: 10 } ]
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:alert]).to be_present
      end
    end

    context "edición válida de un menú publicado" do
      it "no toma como quitado un plato programado con una variante" do
        variant = menu.build_variant(valid_from: target_date, valid_until: target_date)
        variant.save!
        schedule = variant.schedules.create!(date: target_date, amount: 10)

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [ { menu_id: menu.id, amount: 15 } ]
        }

        expect(schedule.reload.amount).to eq(15)
        expect(schedule.menu).to eq(variant)
        expect(Schedule.where(date: target_date, menu_id: menu.family_ids).count).to eq(1)
      end

      it "actualiza el stock de un plato preservando el ID del schedule original" do
        schedule = menu.schedules.create!(date: target_date, amount: 10)
        original_schedule_id = schedule.id

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [
            { menu_id: menu.id, amount: 25 }
          ]
        }

        expect(response).to redirect_to(schedules_path(week_start: target_date.beginning_of_week(:monday).to_s))
        follow_redirect!
        expect(flash[:notice]).to eq("Menú actualizado con éxito.")

        schedule.reload
        expect(schedule.id).to eq(original_schedule_id)
        expect(schedule.amount).to eq(25)
      end

      it "permite agregar un nuevo plato al menú ya publicado del día" do
        target_date = Date.current.next_week(:monday) + 2.days
        menu.schedules.create!(date: target_date, amount: 10)

        second_menu = provider.menus.create!(
          name: "Pastel de papa",
          description: "Casero",
          price: 320
        )

        sign_in(provider_user, role: :provider)

        expect do
          patch update_by_date_schedules_path, params: {
            date: target_date.to_s,
            items: [
              { menu_id: menu.id, amount: 10 },
              { menu_id: second_menu.id, amount: 15 }
            ]
          }
        end.to change(Schedule, :count).by(1)

        new_schedule = Schedule.find_by(menu: second_menu, date: target_date)
        expect(new_schedule).to be_present
        expect(new_schedule.amount).to eq(15)
      end

      it "cancela automáticamente los pedidos pendientes y confirmados al retirar un plato del menú" do
        target_date = Date.current.next_week(:monday) + 3.days
        schedule_to_remove = menu.schedules.create!(date: target_date, amount: 10)

        kept_menu = provider.menus.create!(
          name: "Ensalada César",
          description: "Fresca",
          price: 280
        )
        kept_menu.schedules.create!(date: target_date, amount: 10)

        pending_order = Order.create!(
          consumer: consumers(:one),
          schedule: schedule_to_remove,
          status: :pending,
          amount: 1,
          price: 350,
          discounted_price: 175,
          address: "18 de Julio 1234",
          delivery_method: :office
        )

        confirmed_order = Order.create!(
          consumer: consumers(:one),
          schedule: schedule_to_remove,
          status: :confirmed,
          amount: 2,
          price: 700,
          discounted_price: 350,
          address: "18 de Julio 1234",
          delivery_method: :office
        )

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [
            { menu_id: kept_menu.id, amount: 10 }
          ]
        }

        expect(Schedule.exists?(schedule_to_remove.id)).to be(false)

        pending_order.reload
        expect(pending_order.status).to eq("cancelled")
        expect(pending_order.status_before_cancellation).to eq("pending")
        expect(pending_order.cancelled_by).to eq(provider_user)

        confirmed_order.reload
        expect(confirmed_order.status).to eq("cancelled")
        expect(confirmed_order.status_before_cancellation).to eq("confirmed")
        expect(confirmed_order.cancelled_by).to eq(provider_user)
      end
    end

    context "validaciones y casos borde (bypass de interfaz e integridad)" do
      it "no permite editar un menú de una fecha pasada" do
        past_date = Date.current - 2.days
        schedule = menu.schedules.create!(date: past_date, amount: 10)

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: past_date.to_s,
          items: [
            { menu_id: menu.id, amount: 20 }
          ]
        }

        expect(response).to redirect_to(schedules_path)
        expect(schedule.reload.amount).to eq(10)
      end

      it "rechaza stock con valor cero" do
        schedule = menu.schedules.create!(date: target_date, amount: 10)

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [
            { menu_id: menu.id, amount: 0 }
          ]
        }

        expect(response).to redirect_to(schedules_path)
        expect(schedule.reload.amount).to eq(10)
      end

      it "rechaza stock con valor negativo" do
        schedule = menu.schedules.create!(date: target_date, amount: 10)

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [
            { menu_id: menu.id, amount: -5 }
          ]
        }

        expect(response).to redirect_to(schedules_path)
        expect(schedule.reload.amount).to eq(10)
      end

      it "rechaza stock no numérico" do
        schedule = menu.schedules.create!(date: target_date, amount: 10)

        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {
          date: target_date.to_s,
          items: [
            { menu_id: menu.id, amount: "invalido" }
          ]
        }

        expect(response).to redirect_to(schedules_path)
        expect(schedule.reload.amount).to eq(10)
      end

      it "devuelve 404 y revierte la transacción si se intenta incluir un plato de otro proveedor" do
        schedule = menu.schedules.create!(date: target_date, amount: 10)
        foreign_menu = menus(:sorrentinos)

        sign_in(provider_user, role: :provider)

        expect do
          patch update_by_date_schedules_path, params: {
            date: target_date.to_s,
            items: [
              { menu_id: menu.id, amount: 20 },
              { menu_id: foreign_menu.id, amount: 15 }
            ]
          }
        end.not_to change(Schedule, :count)

        expect(response).to have_http_status(:not_found)
        expect(schedule.reload.amount).to eq(10)
      end

      it "devuelve bad request si faltan parámetros requeridos" do
        sign_in(provider_user, role: :provider)

        patch update_by_date_schedules_path, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PATCH /schedules/:id/availability" do
    it "marks the publication as sold out and records who and when" do
      user = users(:one)
      provider = Provider.create!(user: user)
      menu = provider.menus.create!(name: "Milanesa", description: "Con puré", price: 350)
      schedule = menu.schedules.create!(date: next_publishable_date, amount: 10)

      sign_in_with_role(user, role: :provider)

      freeze_time do
        patch availability_schedule_path(schedule), params: { available: false }

        expect(schedule.reload).to have_attributes(
          available: false,
          availability_changed_by: user,
          availability_changed_at: Time.current
        )
      end

      expect(response).to redirect_to(schedules_path(week_start: schedule.date.beginning_of_week(:monday).to_s))
    end

    it "marks the publication as available again" do
      user = users(:one)
      provider = Provider.create!(user: user)
      menu = provider.menus.create!(name: "Milanesa", description: "Con puré", price: 350)
      schedule = menu.schedules.create!(date: next_publishable_date, amount: 10, available: false)

      sign_in_with_role(user, role: :provider)

      patch availability_schedule_path(schedule), params: { available: true }

      expect(schedule.reload.available).to be(true)
    end

    it "sends back the errors and changes nothing when the publication can't be saved" do
      user = users(:one)
      provider = Provider.create!(user: user)
      menu = provider.menus.create!(name: "Milanesa", description: "Con puré", price: 350)
      schedule = menu.schedules.create!(date: next_publishable_date, amount: 10)
      # La base ya rechaza los datos que harían fallar el update: se simula.
      allow_any_instance_of(Schedule).to receive(:set_availability) do |record|
        record.errors.add(:base, "No se pudo guardar")
        false
      end

      sign_in_with_role(user, role: :provider)

      patch availability_schedule_path(schedule), params: { available: false }

      expect(response).to redirect_to(schedules_path)
      expect(schedule.reload).to have_attributes(available: true, availability_changed_by: nil)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:base)
    end

    it "returns not found when attempting to toggle another provider's publication" do
      owner = users(:one)
      provider = Provider.create!(user: owner)
      menu = provider.menus.create!(name: "Milanesa", description: "Con puré", price: 350)
      schedule = menu.schedules.create!(date: next_publishable_date, amount: 10)

      other = users(:two)
      Provider.create!(user: other)
      sign_in_with_role(other, role: :provider)

      patch availability_schedule_path(schedule), params: { available: false }

      expect(response).to have_http_status(:not_found)
      expect(schedule.reload.available).to be(true)
    end
  end
end
