# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Menus", type: :request do
  fixtures :users, :providers, :menus, :consumers, :menu_option_groups, :schedules, :orders, :companies, :admins

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:other_provider_user) { users(:other_provider_user) }
  let(:other_provider) { providers(:endulzate) }

  describe "GET /provider/menus" do
    it "redirects visitors without a session to the sign in page" do
      get provider_menus_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_menus_path

      expect(response).to redirect_to(root_path)
    end

    it "lists the menus of the signed-in provider in descending creation order" do
      sign_in provider_user, role: :provider

      get provider_menus_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider/menus/index")

      listed_menus = inertia.props[:menus]
      expect(listed_menus.map { |m| m["id"] }).to include(menus(:milanesa).id)
      expect(listed_menus.map { |m| m["id"] }).not_to include(menus(:sorrentinos).id)
    end
  end

  describe "POST /provider/menus" do
    before { sign_in provider_user, role: :provider }

    it "creates a new dish with option groups and redirects to the index" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Suprema napolitana",
            price: 360.0,
            description: "Con guarnición a elección",
            option_groups_attributes: [
              { name: "Salsa", options: [ "Tuco", "Caruso" ], limit: 1 },
              { name: "Guarnición", options: [ "Papas fritas", "Ensalada" ], limit: 1 }
            ]
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      created = provider.menus.order(:id).last
      expect(created.name).to eq("Suprema napolitana")
      expect(created.option_groups.count).to eq(2)
      expect(created.option_groups.find_by(name: "Salsa").options).to eq([ "Tuco", "Caruso" ])
    end

    it "creates a dish without option groups" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Ensalada César",
            description: "Ensalada con pollo, lechuga y aderezo César",
            price: 290.0
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      expect(provider.menus.order(:id).last.option_groups).to be_empty
    end

    it "rejects a dish with duplicate options in a group" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Plato",
            price: 300.0,
            option_groups_attributes: [ { name: "Salsa", options: [ "Tuco", "Tuco" ], limit: 1 } ]
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:"option_groups.options")
    end

    it "rejects a dish without a name and returns validation errors" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "",
            price: 300.0
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:name)
    end

    it "rejects a dish with non-positive price" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Plato inválido",
            price: 0
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:price)
    end
  end

  describe "GET /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "renders the dish detail for the provider's own dish" do
      get provider_menu_path(menus(:milanesa))

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider/menus/show")
      expect(inertia.props[:menu]["name"]).to eq("Milanesa con papas fritas")
    end

    it "returns not found when attempting to view another provider's dish" do
      get provider_menu_path(menus(:sorrentinos))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /provider/menus/:id/edit" do
    it "redirects visitors without a session to the sign in page" do
      get edit_provider_menu_path(menus(:milanesa))

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get edit_provider_menu_path(menus(:milanesa))

      expect(response).to redirect_to(root_path)
    end

    it "redirects admins to the root page" do
      sign_in users(:admin), role: :admin

      get edit_provider_menu_path(menus(:milanesa))

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as provider" do
      before { sign_in provider_user, role: :provider }

      it "renders the edit page for the provider's own dish" do
        menu = menus(:milanesa)

        get edit_provider_menu_path(menu)

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("provider/menus/edit")
        expect(inertia.props[:menu]["id"]).to eq(menu.id)
        expect(inertia.props[:menu]["name"]).to eq(menu.name)
        expect(inertia.props[:menu]).to have_key("option_groups")
      end

      it "serializes exact Inertia props for a dish with an existing weekly agenda" do
        menu = menus(:milanesa)
        menu.agendas.create!(weekdays: [ 1, 3 ], starts_on: Date.current, amount: 8)

        get edit_provider_menu_path(menu)

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("provider/menus/edit")
        expect(inertia).to have_props(
          saved_menu_id: menu.id,
          schedule_date: nil,
          today: Date.current.iso8601,
          maximum_publish_date: Calendar.new.maximum_publish_date.iso8601
        )
        agenda_prop = inertia.props[:agenda].deep_symbolize_keys
        expect(agenda_prop[:mode]).to eq("weekly")
        expect(agenda_prop[:weekdays]).to eq([ 1, 3 ])
        expect(agenda_prop[:amount]).to eq(8)
      end

      it "serializes mode none when dish has no agenda and no schedule" do
        menu = provider.menus.create!(name: "Pastel", description: "De carne", price: 200)

        get edit_provider_menu_path(menu)

        agenda_prop = inertia.props[:agenda].deep_symbolize_keys
        expect(agenda_prop[:mode]).to eq("none")
        expect(agenda_prop[:weekdays]).to eq([])
        expect(agenda_prop[:amount]).to be_nil
      end

      it "returns not found when attempting to edit another provider's dish" do
        get edit_provider_menu_path(menus(:sorrentinos))

        expect(response).to have_http_status(:not_found)
      end

      it "edits the dish as it is programmed on the day it was opened from" do
        schedule = schedules(:future)

        get edit_provider_menu_path(menus(:milanesa), schedule_id: schedule.id)

        expect(inertia).to have_props { |props|
          props = props.deep_symbolize_keys

          props[:schedule_date] == schedule.date.iso8601 &&
            props[:agenda][:mode] == "single" &&
            props[:agenda][:date] == schedule.date.iso8601 &&
            props[:scheduled_days].find { it[:date] == schedule.date.iso8601 }[:confirmed_orders] ==
              schedule.orders.confirmed.count
        }
      end

      it "opens a day programmed by a range with that range's agenda" do
        starts_on = Date.current.next_week(:monday)
        ends_on = starts_on + 4.days
        variant = menus(:milanesa).build_variant(valid_from: starts_on, valid_until: ends_on)
        variant.agendas.build(weekdays: [ 2, 4 ], starts_on:, ends_on:, amount: 6)
        variant.save!
        schedule = variant.schedules.create!(date: starts_on + 1.day, amount: 6)

        get edit_provider_menu_path(menus(:milanesa), schedule_id: schedule.id)

        expect(inertia).to have_props { |props|
          props.deep_symbolize_keys[:agenda] == {
            mode: "range", weekdays: [ 2, 4 ], starts_on: starts_on.iso8601,
            ends_on: ends_on.iso8601, date: nil, amount: 6
          }
        }
      end

      it "does not open a day programmed with another dish" do
        get edit_provider_menu_path(menus(:milanesa), schedule_id: schedules(:sorrentinos_today).id)

        expect(response).to have_http_status(:not_found)
      end

      it "does not open a variant as if it were a saved dish" do
        variant = menus(:milanesa).build_variant(valid_from: Date.current, valid_until: Date.current)
        variant.save!

        get edit_provider_menu_path(variant)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /provider/menus/:id" do
    it "redirects visitors without a session to the sign in page" do
      patch provider_menu_path(menus(:milanesa)), params: { menu: { name: "Nuevo" } }

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      patch provider_menu_path(menus(:milanesa)), params: { menu: { name: "Nuevo" } }

      expect(response).to redirect_to(root_path)
    end

    it "redirects admins to the root page" do
      sign_in users(:admin), role: :admin

      patch provider_menu_path(menus(:milanesa)), params: { menu: { name: "Nuevo" } }

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as provider" do
      before { sign_in provider_user, role: :provider }

      it "updates option groups of an existing dish" do
      menu = menus(:milanesa)
      group = menu.option_groups.create!(name: "Salsa", options: [ "Tuco" ], limit: 1)

      patch provider_menu_path(menu), params: {
        menu: {
          option_groups_attributes: [ { id: group.id, name: "Salsa", options: [ "Tuco", "Caruso" ], limit: 2 } ]
        }
      }

      expect(response).to redirect_to(edit_provider_menu_path(menu))
      expect(group.reload.options).to eq([ "Tuco", "Caruso" ])
      expect(group.reload.limit).to eq(2)
    end

      it "updates the provider's dish information and records audit data" do
        menu = menus(:milanesa)

        freeze_time do
          patch provider_menu_path(menu), params: {
            menu: {
              name: "Milanesa napolitana",
              description: "Con papas fritas y ensalada",
              price: 420.50
            }
          }

          expect(response).to redirect_to(edit_provider_menu_path(menu))

          menu.reload
          expect(menu.name).to eq("Milanesa napolitana")
          expect(menu.description).to eq("Con papas fritas y ensalada")
          expect(menu.price).to eq(420.50)
          expect(menu.modified_by).to eq(provider_user)
          expect(menu.modified_at).to eq(Time.current)
          expect(menu.modified_values).to eq(
            "name" => [ "Milanesa con papas fritas", "Milanesa napolitana" ],
            "description" => [ "Opción de carne o pollo", "Con papas fritas y ensalada" ],
            "price" => [ "300.5", "420.5" ]
          )
        end
      end

      it "returns validation errors when the changes are invalid" do
        menu = menus(:milanesa)

        patch provider_menu_path(menu), params: {
          menu: {
            name: "",
            description: "",
            price: 0
          }
        }

        expect(response).to redirect_to(edit_provider_menu_path(menu))

        follow_redirect!
        expect(inertia.props[:errors]).to have_key(:name)
        expect(inertia.props[:errors]).to have_key(:price)
        expect(inertia.props[:errors]).to have_key(:description)
      end

      it "returns not found when attempting to update another provider's dish" do
        menu = menus(:sorrentinos)
        original_name = menu.name

        patch provider_menu_path(menu), params: {
          menu: {
            name: "No debería cambiar",
            price: 999
          }
        }

        expect(response).to have_http_status(:not_found)
        expect(menu.reload.name).to eq(original_name)
      end

      it "removes an option group with _destroy" do
        menu = menus(:milanesa)
        group = menu.option_groups.create!(name: "Salsa", options: [ "Tuco" ], limit: 1)

        expect do
          patch provider_menu_path(menu), params: {
            menu: {
              option_groups_attributes: [ { id: group.id, _destroy: true } ]
            }
          }
        end.to change(MenuOptionGroup, :count).by(-1)

        expect(response).to redirect_to(edit_provider_menu_path(menu))
      end
    end
  end

  describe "PATCH /provider/menus/:id from a programmed day" do
    before { sign_in provider_user, role: :provider }

    let(:schedule) { schedules(:future) }
    let(:params) do
      {
        menu: { name: "Milanesa napolitana", description: "Con jamón y queso", price: 350 },
        agenda: { mode: "single", date: schedule.date.iso8601, amount: schedule.amount },
        scope: "day",
        schedule_id: schedule.id
      }
    end

    # El día de la programación de los fixtures puede caer en fin de semana.
    before { schedule.update!(date: Date.current.next_occurring(:wednesday)) }

    it "changes only that day and leaves the saved dish untouched" do
      patch provider_menu_path(menus(:milanesa)), params: params

      expect(response).to redirect_to(edit_provider_menu_path(menus(:milanesa), schedule_id: schedule.id))
      expect(schedule.reload.menu.name).to eq("Milanesa napolitana")
      expect(menus(:milanesa).reload.name).to eq("Milanesa con papas fritas")
    end

    it "rejects the confirmed orders of that day when the provider asks to" do
      patch provider_menu_path(menus(:milanesa)), params: params.merge(confirmed_orders: "reject")

      expect(orders(:upcoming_confirmed_future).reload).to be_rejected
      expect(orders(:upcoming_confirmed_future)).to be_rejection_reason_dish_modified
      expect(orders(:upcoming_pending_future).reload).to be_pending
    end

    it "keeps confirmed orders when confirmed_orders param is omitted" do
      patch provider_menu_path(menus(:milanesa)), params: params.except(:confirmed_orders)

      expect(orders(:upcoming_confirmed_future).reload).to be_confirmed
    end

    it "returns 404 when attempting to update a variant ID directly" do
      variant = menus(:milanesa).build_variant(valid_from: Date.current, valid_until: Date.current)
      variant.save!

      patch provider_menu_path(variant), params: params

      expect(response).to have_http_status(:not_found)
    end

    it "keeps showing the old dish on the orders it already had" do
      order = Order.reserve(consumer: consumers(:one), schedule:, delivery_method: :office, address: nil, benefits: [])

      patch provider_menu_path(menus(:milanesa)), params: params

      sign_in users(:one), role: :consumer
      get order_path(order)

      expect(inertia.props[:order][:menu_name]).to eq("Milanesa con papas fritas")
    end

    it "returns the agenda errors" do
      patch provider_menu_path(menus(:milanesa)), params: params.deep_merge(agenda: { amount: 0 })

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:agenda)
    end

    it "returns agenda errors for malformed or invalid agenda parameters" do
      patch provider_menu_path(menus(:milanesa)), params: params.deep_merge(
        agenda: { mode: "range", weekdays: [], starts_on: "invalid-date", ends_on: "invalid-date" }
      )

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:agenda)
    end

    it "keeps the variants out of the saved dishes list" do
      patch provider_menu_path(menus(:milanesa)), params: params

      get provider_menus_path

      expect(inertia.props[:menus].pluck("name")).not_to include("Milanesa napolitana")
    end
  end

  describe "DELETE /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "deletes the dish and redirects to index" do
      menu_to_delete = provider.menus.create!(
        name: "Pastel de carne",
        description: "Pastel de carne con puré",
        price: 280
      )

      expect do
        delete provider_menu_path(menu_to_delete)
      end.to change(provider.menus, :count).by(-1)

      expect(response).to redirect_to(provider_menus_path)
    end

    it "returns not found when attempting to delete another provider's dish" do
      expect do
        delete provider_menu_path(menus(:sorrentinos))
      end.not_to change(Menu, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
