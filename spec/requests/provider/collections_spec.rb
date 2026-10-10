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

    %i[beginning_of_month end_of_month].each do |boundary|
      it "includes the confirmed sales detail grouped by delivery day at #{boundary}" do
        month = Date.current.beginning_of_month
        dates = month.all_month.reject { it == schedules(:today).date }
        schedules(:past).update!(date: dates.first)
        schedules(:future).update!(date: dates.last)

        travel_to Time.zone.local(month.year, month.month, month.public_send(boundary).day, 12) do
          sign_in provider_user, role: :provider

          get provider_collections_path

          expect(inertia).to have_props(sales: { total: 1202.0, meals: 4 })
          expect(inertia).to have_props { |page|
            detail = page[:sales_detail]
            detail_orders = detail[:days].flat_map { it[:orders] }

            expect(detail[:month]).to eq(I18n.l(month, format: :month_name_year))
            expect(detail[:clients]).to eq([ { "id" => companies(:gogrow).id, "name" => "GoGrow" } ])
            expect(detail_orders.pluck(:id)).to match_array(
              [ orders(:upcoming_confirmed_future), orders(:history_confirmed_past), orders(:other_consumer_upcoming) ].map(&:id)
            )
            expect(detail_orders.sum { it[:meals] }).to eq(4)
            expect(detail_orders.sum { it[:amount] }).to eq(1202.0)
            expect(detail[:days].pluck(:date)).to eq([ dates.last, dates.first ].map { it.strftime("%d/%m") })
            true
          }
        end
      end
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
      expect(group[:company][:orders].pluck(:id)).to match_array(
        [ orders(:upcoming_confirmed_future), orders(:history_confirmed_past), orders(:other_consumer_upcoming) ].map(&:id)
      )
      expect(group[:employees].flat_map { it[:orders] }.pluck(:id)).to match_array(
        [ orders(:upcoming_confirmed_future), orders(:history_confirmed_past), orders(:other_consumer_upcoming) ].map(&:id)
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

    it "includes every payment receipt in the history, newest first" do
      employee_account = accounts(:one_tuviandita_current)
      other_employee_account = accounts(:other_tuviandita_current)
      company_account = accounts(:gogrow_tuviandita_current)

      employee_account.payments.destroy_all

      rejected = employee_account.payments.create!(
        provider: employee_account.provider,
        status: :rejected,
        rejection_reason: "Comprobante inválido",
        created_at: 2.days.ago,
        receipt: Rack::Test::UploadedFile.new(
          Rails.root.join("public/icon.png"),
          "image/png",
          original_filename: "rechazado.png"
        )
      )

      approved = employee_account.payments.create!(
        provider: employee_account.provider,
        status: :approved,
        created_at: 1.day.ago,
        receipt: Rack::Test::UploadedFile.new(
          Rails.root.join("public/icon.png"),
          "image/png",
          original_filename: "aprobado.png"
        )
      )

      # Se destruye el comprobante "submitted" de la fixture: desde que
      # collection_status prioriza cualquier pago sin revisar (ver
      # Account#payment_pending_review), dejarlo vivo mantendría a este grupo
      # en Pendientes en vez de pasar a Historial.
      other_employee_account.payments.destroy_all

      other_employee_account.payments.create!(
        provider: other_employee_account.provider,
        status: :approved
      )

      company_account.payments.create!(
        provider: company_account.provider,
        status: :approved
      )

      sign_in provider_user, role: :provider

      get provider_collections_path

      employee = group_for(:history, Date.current)[:employees]
        .find { it[:id] == employee_account.id }

      expect(employee[:payments].pluck(:id)).to eq([ approved.id, rejected.id ])

      expect(employee[:payments].first).to include(
        status: "approved",
        rejection_reason: nil,
        date: approved.created_at.strftime("%d/%m/%y"),
        receipt_url: receipt_provider_payment_path(approved),
        receipt_filename: "aprobado.png",
        receipt_content_type: "image/png"
      )

      expect(employee[:payments].second).to include(
        status: "rejected",
        rejection_reason: "Comprobante inválido",
        date: rejected.created_at.strftime("%d/%m/%y"),
        receipt_url: receipt_provider_payment_path(rejected),
        receipt_filename: "rechazado.png",
        receipt_content_type: "image/png"
      )
    end

    it "shows the invoice uploaded for the company period" do
      Invoice.create!(
        account: accounts(:gogrow_tuviandita_current),
        issued_on: Date.current,
        total_amount: 601,
        file: Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: "factura.png")
      )
      sign_in provider_user, role: :provider

      get provider_collections_path

      group = group_for(:pending, Date.current)

      expect(group[:company][:invoice]).to include(status: "pending", file_name: "factura.png", removable: true, total_amount: 601.0)
      expect(group[:employees].pluck(:invoice)).to all(be_nil)
      expect(group_for(:history, 1.month.ago.to_date)[:company][:invoice]).to be_nil
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
    it "keeps the individual orders available after the group is settled" do
      current_accounts = providers(:tuviandita).accounts.current
      current_accounts.each do |account|
        account.payments.destroy_all
        account.payments.create!(provider: account.provider, status: :approved)
      end
      account = accounts(:gogrow_tuviandita_current)
      order_ids = account.orders.confirmed.ids
      sign_in provider_user, role: :provider

      get provider_collections_path

      expect(inertia).to have_props { |page|
        page[:history].any? { it[:company]&.slice(:id, :status, :orders) == { "id" => account.id, "status" => "approved", "orders" => [] } }
      }

      get provider_collection_path(account)

      expect(inertia).to render_component("provider/collections/show")
      expect(inertia).to have_props { |page|
        page[:orders].pluck(:id).sort == order_ids.sort &&
          page[:account][:status] == "approved" && page[:account][:orders].pluck(:id).sort == order_ids.sort
      }
    end

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
