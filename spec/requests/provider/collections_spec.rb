# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Collections", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :accounts, :order_accounts, :payments

  let(:provider_user) { users(:provider_user) }

  def props
    inertia.props.deep_symbolize_keys
  end

  def group_for(tab, month)
    props[tab].find { it[:month] == I18n.l(month, format: :month_name_year) }
  end

  describe "GET /provider/collections" do
    it "redirects to sign in without a session" do
      get provider_collections_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get provider_collections_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects an admin to the home page" do
      admin_user = User.create!(email: "admin-collections@gmail.com", name: "Admin", password: "password123456")
      Admin.create!(user: admin_user, company: companies(:gogrow))
      sign_in admin_user, role: :admin

      get provider_collections_path

      expect(response).to redirect_to(root_path)
    end

    it "sums the sales of the month and the debt still owed" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      expect(inertia).to render_component("provider/collections/index")
      # Cuatro viandas confirmadas: cada pedido se cuenta una vez aunque cuelgue
      # de la cuenta del empleado y de la de la empresa.
      expect(props[:sales]).to include(total: 1202.0, meals: 4)
      expect(props[:outstanding]).to include(total: 1202.0, meals: 4)
    end

    it "groups what each client owes by month, with the company and its employees" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      group = group_for(:pending, Date.current)

      expect(group).to include(client_name: "GoGrow", total: 1202.0, confirmed_total: 0.0, meals: 4)
      expect(group[:company]).to include(owner_name: "GoGrow", amount: 601.0, status: "pending")
      expect(group[:employees].pluck(:owner_name, :status)).to eq(
        [ [ "Other Consumer User", "submitted" ], [ "Test User", "rejected" ] ]
      )
    end

    it "counts what is awaiting confirmation and what was rejected" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      group = group_for(:pending, Date.current)

      expect(group).to include(awaiting_count: 2, rejected_count: 1, employees_total: 601.0)
      # Un rechazo pide más atención que un pago por revisar.
      expect(group[:employees_status]).to eq("rejected")
    end

    it "moves a month to the history once every account is confirmed" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      expect(props[:pending].pluck(:month)).to eq([ I18n.l(Date.current, format: :month_name_year) ])
      expect(group_for(:history, 1.month.ago.to_date)).to include(total: 900.0, confirmed_total: 900.0)
      expect(group_for(:history, 1.month.ago.to_date)[:company][:paid_on]).to be_present
    end

    it "leaves out the accounts of other providers" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      ids = (props[:pending] + props[:history]).flat_map { [ it[:company], *it[:employees] ] }.compact.pluck(:id)

      expect(ids).to match_array(
        [ accounts(:gogrow_tuviandita_current), accounts(:one_tuviandita_current),
          accounts(:other_tuviandita_current), accounts(:gogrow_tuviandita_previous) ].map(&:id)
      )
    end

    it "offers the clients to filter by" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      expect(props[:clients]).to eq([ { id: companies(:gogrow).id, name: "GoGrow" } ])
    end

    it "keeps each total equal to the sum of its accounts" do
      sign_in provider_user, role: :provider

      get provider_collections_path

      (props[:pending] + props[:history]).each do |group|
        accounts = [ group[:company], *group[:employees] ].compact

        expect(group[:total]).to eq(accounts.sum { it[:amount] })
        expect(group[:employees_total]).to eq(group[:employees].sum { it[:amount] })
      end
    end
  end

  describe "GET /provider/collections/:id" do
    it "shows the orders and the payments that make up the total" do
      sign_in provider_user, role: :provider

      get provider_collection_path(accounts(:gogrow_tuviandita_current))

      expect(inertia).to render_component("provider/collections/show")
      expect(props[:account]).to include(owner_name: "GoGrow", amount: 601.0)
      expect(props[:orders].pluck(:id)).to match_array(
        [ orders(:upcoming_confirmed_future), orders(:history_confirmed_past), orders(:other_consumer_upcoming) ].map(&:id)
      )
      expect(props[:orders].sum { it[:subsidy] }).to eq(601.0)
    end

    it "lists the payments of the account, newest first" do
      sign_in provider_user, role: :provider

      get provider_collection_path(accounts(:one_tuviandita_current))

      expect(props[:payments].pluck(:status)).to eq([ "rejected" ])
    end

    it "does not find the account of another provider" do
      sign_in users(:other_provider_user), role: :provider

      get provider_collection_path(accounts(:gogrow_tuviandita_current))

      expect(response).to have_http_status(:not_found)
    end
  end
end
