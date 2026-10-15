# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Payments", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus, :schedules,
           :orders, :accounts, :order_accounts, :payments

  # La cuenta de otra empresa se crea acá y no en los fixtures: las cuentas se
  # cuentan en los specs de cobros y una fila más les cambiaría los totales.
  let(:other_company_account) do
    company = Company.create!(name: "Otra empresa", address: "Rincón 500")

    Account.create!(owner: company, provider: providers(:tuviandita), month: Date.current, amount: 100.00)
  end

  def receipt_upload(content_type: "image/png", filename: "comprobante.png")
    Rack::Test::UploadedFile.new(
      Rails.root.join(content_type == "text/plain" ? "public/robots.txt" : "public/icon.png"),
      content_type,
      original_filename: filename
    )
  end

  def oversized_receipt
    Tempfile.create([ "comprobante-grande", ".png" ]) do |file|
      file.binmode
      file.write("x" * (10.megabytes + 1))
      file.rewind

      yield Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "comprobante-grande.png")
    end
  end

  describe "GET /admin/payments" do
    it "redirects to sign in without a session" do
      get admin_payments_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      get admin_payments_path

      expect(response).to redirect_to(root_path)
    end

    context "when signed in as HR" do
      before { sign_in users(:admin), role: :admin }

      it "muestra el mismo total con IVA que el proveedor y conserva el subtotal" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("COMPANY_ACCOUNT_VAT_ENABLED").and_return("true")
        account = Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current, amount: "800")

        get admin_payments_path

        expect(inertia).to have_props(total_debt: 1577.0, current_month: { amount: 1577.0, meals: 4, limit: 40 })
        expect(inertia).to have_props { |page|
          page[:accounts].any? { it[:id] == account.id && it[:amount] == 800.0 && it[:vat_amount] == 176.0 && it[:payable_amount] == 976.0 }
        }
        expect(account.reload.amount).to eq(800.to_d)
      end

      it "lists only what the company still owes, and not what its employees owe" do
        other_company_account

        get admin_payments_path

        expect(inertia).to render_component("admin/payments/index")
        expect(inertia.props[:accounts].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_current).id)
        expect(inertia.props[:total_debt]).to eq(601.0)
      end

      it "moves a period with an approved receipt to the history" do
        get admin_payments_path

        expect(inertia.props[:history].pluck(:id)).to contain_exactly(accounts(:gogrow_tuviandita_previous).id)
      end

      # Con un comprobante viejo sin revisar, el período sigue en revisión
      # aunque haya otro aprobado después: es la regla de Account#collection_status,
      # la misma que usa el inicio de RR. HH.
      it "shows a period with the same status as the home when an older receipt is still under review" do
        account = accounts(:gogrow_tuviandita_previous)
        older = account.payments.build(provider: account.provider, status: :submitted, created_at: 1.day.ago)
        older.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
        older.save!

        get admin_dashboard_path
        home_status = inertia.props[:payments].sole["status"]

        get admin_payments_path
        period = inertia.props[:accounts].find { it[:id] == account.id }

        expect(home_status).to eq("submitted")
        expect(period[:collection_status]).to eq(home_status)
        expect(inertia.props[:history].pluck(:id)).not_to include(account.id)
      end

      it "counts the subsidy and the meals of the current month" do
        get admin_payments_path

        expect(inertia.props[:current_month]).to eq("amount" => 601.0, "meals" => 4, "limit" => 40)
      end

      it "counts the meals of what the company still owes" do
        get admin_payments_path

        expect(inertia).to have_props(total_debt: 601.0, total_meals: 4)
      end

      it "sends the payment details each provider loaded, without its tax id" do
        providers(:endulzate).update!(
          bank_name: "Banco Itaú", bank_account_type: :checking, bank_account_number: "1951234",
          bank_account_holder: "Noelia Patricia Pinheiro", tax_id: "211234560019"
        )

        get admin_payments_path

        endulzate = inertia.props[:providers].find { it[:id] == providers(:endulzate).id }
        expect(endulzate).to include(
          bank_name: "Banco Itaú", bank_account_number: "1951234", bank_account_holder: "Noelia Patricia Pinheiro"
        )
        expect(endulzate).not_to have_key(:tax_id)
        expect(inertia.props[:providers].find { it[:id] == providers(:tuviandita).id })
          .to include(bank_name: nil, bank_account_number: nil, bank_account_holder: nil)
      end

      it "lists every provider so the ones without debt also show up" do
        get admin_payments_path

        expect(inertia.props[:providers].pluck(:name))
          .to eq([ "Office Provider User", "Other Provider User", "Provider User" ])
      end

      # El inicio de RR. HH. llega con ?month= desde "Ver detalle del consumo".
      it "opens the detail of the month the URL asks for on the pending tab" do
        get admin_payments_path, params: { month: Date.current.strftime("%Y-%m") }

        period = inertia.props[:period]
        expect(period).to include(
          "month" => I18n.l(Date.current.beginning_of_month, format: :month_name_year).upcase_first,
          "tab" => "pending"
        )
        expect(period["providers"].sole).to include(
          "id" => providers(:tuviandita).id, "name" => "Provider User", "meals" => 4,
          "subtotal" => 601.0, "vat_rate" => 0.0, "vat_amount" => 0.0, "payable_amount" => 601.0
        )
        expect(period["providers"].sole["days"].flat_map { it["orders"] }.pluck("id")).to contain_exactly(
          orders(:upcoming_confirmed_future).id, orders(:history_confirmed_past).id, orders(:other_consumer_upcoming).id
        )
      end

      it "splits what the employee pays from what GoGrow pays in each order" do
        get admin_payments_path, params: { month: Date.current.strftime("%Y-%m") }

        rows = inertia.props[:period]["providers"].sole["days"].flat_map { it["orders"] }
        expect(rows.find { it["id"] == orders(:upcoming_confirmed_future).id }).to include(
          "consumer_name" => users(:one).name, "meals" => 2, "employee_amount" => 300.5, "company_amount" => 300.5
        )
      end

      it "sends one detail per provider of the month, sorted by name" do
        Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current, amount: 200)

        get admin_payments_path

        expect(inertia.props[:current_period]["providers"].pluck("name")).to eq([ "Other Provider User", "Provider User" ])
      end

      it "breaks down the VAT of each provider with its own rate" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("COMPANY_ACCOUNT_VAT_ENABLED").and_return("true")
        Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current, amount: 800)

        get admin_payments_path

        expect(inertia.props[:current_period]["providers"].find { it["id"] == providers(:endulzate).id }).to include(
          "subtotal" => 800.0, "vat_rate" => 22.0, "vat_amount" => 176.0, "payable_amount" => 976.0, "days" => []
        )
      end

      it "opens an already paid month on the history tab" do
        get admin_payments_path, params: { month: 1.month.ago.strftime("%Y-%m") }

        expect(inertia.props[:period]).to include("tab" => "history")
        expect(inertia.props[:period]["providers"].sole).to include("subtotal" => 900.0, "days" => [])
      end

      it "sends the detail of the current month for the consumption card" do
        get admin_payments_path

        expect(inertia.props[:current_period]).to include(
          "month" => I18n.l(Date.current.beginning_of_month, format: :month_name_year).upcase_first
        )
        expect(inertia.props[:current_period]["providers"].sole["subtotal"]).to eq(601.0)
      end

      it "opens nothing without a month, with an invalid one or with one without payments" do
        [ nil, "agosto", "2020-01" ].each do |month|
          get admin_payments_path, params: { month: }.compact

          expect(inertia.props[:period]).to be_nil
        end
      end

      it "does not open the period of another company" do
        other_company_account

        get admin_payments_path, params: { month: Date.current.strftime("%Y-%m") }

        expect(inertia.props[:period]["providers"].pluck("subtotal")).to eq([ 601.0 ])
      end
    end
  end

  describe "GET /admin/payments/:id" do
    it "redirects to sign in without a session" do
      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      expect(response).to redirect_to(sign_in_path)
    end

    it "answers with the detail of every provider of the period's month" do
      Account.create!(owner: companies(:gogrow), provider: providers(:endulzate), month: Date.current, amount: 200)
      sign_in users(:admin), role: :admin

      get admin_payment_path(accounts(:gogrow_tuviandita_current))

      body = response.parsed_body

      expect(body["month"]).to eq(I18n.l(Date.current.beginning_of_month, format: :month_name_year).upcase_first)
      expect(body["providers"].pluck("name", "subtotal")).to eq([ [ "Other Provider User", 200.0 ], [ "Provider User", 601.0 ] ])
      expect(body["providers"].last["days"].flat_map { it["orders"] }.pluck("id")).to contain_exactly(
        orders(:upcoming_confirmed_future).id,
        orders(:history_confirmed_past).id,
        orders(:other_consumer_upcoming).id
      )
    end

    it "responds with not found for an account of another company" do
      sign_in users(:admin), role: :admin

      get admin_payment_path(other_company_account)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /admin/payments" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    it "creates a submitted payment with a receipt for the company account" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(1)

      payment = account.payments.reload.order(:created_at).last
      expect(response).to redirect_to(admin_payments_path)
      expect(payment).to be_submitted
      expect(payment.provider).to eq(account.provider)
      expect(payment.receipt).to be_attached
      expect(payment.receipt.filename.to_s).to eq("comprobante.png")
    end

    it "does not allow a second receipt while one is under review for the same company account" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload(filename: "comprobante_1.png") }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(1)

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload(filename: "comprobante_2.png") }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(admin_payments_path)
      expect(account.payments.reload.submitted.count).to eq(1)
      expect(account.payments.submitted.sole.receipt.filename.to_s).to eq("comprobante_1.png")
    end

    it "resolves the pending payment alert of the account" do
      sign_in users(:admin), role: :admin
      reminder = Notifier.call(
        event_key: :company_payment_overdue,
        user: users(:admin),
        notifiable: account,
        description_data: { company: "GoGrow", provider: "TuViandita", period: "agosto 2026", amount: "$601", due_date: "5/9/2026" }
      )

      post admin_payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: { "HTTP_REFERER" => admin_payments_url }

      expect(reminder.reload.closed_at).to be_present
    end

    it "does not create a payment for another company's account" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: other_company_account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns the shared file validation errors" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: {
            account_id: account.id,
            receipt: receipt_upload(content_type: "text/plain", filename: "comprobante.txt")
          }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.invalid_content_type") ]
        }
      )
    end

    it "rejects a receipt larger than 10 MB without persisting the payment" do
      sign_in users(:admin), role: :admin

      oversized_receipt do |receipt|
        expect {
          post admin_payments_path, params: {
            payment: { account_id: account.id, receipt: }
          }, headers: { "HTTP_REFERER" => admin_payments_url }
        }.not_to change(Payment, :count)
      end

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.too_large") ]
        }
      )
    end

    it "requires a receipt" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id }
        }, headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      follow_redirect!
      expect(inertia).to have_props(
        errors: {
          receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.required") ]
        }
      )
    end

    it "does not allow a consumer to upload a company receipt" do
      sign_in users(:one), role: :consumer

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(root_path)
    end

    it "does not allow a provider to upload a company receipt" do
      sign_in users(:provider_user), role: :provider

      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(root_path)
    end

    it "requires an admin session" do
      expect {
        post admin_payments_path, params: {
          payment: { account_id: account.id, receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "rescues ActiveRecord::RecordNotUnique and redirects with already_under_review error prop" do
      sign_in users(:admin), role: :admin
      allow_any_instance_of(Payment).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      post admin_payments_path, params: {
        payment: { account_id: account.id, receipt: receipt_upload }
      }, headers: { "HTTP_REFERER" => admin_payments_url }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(admin_payments_path)
      follow_redirect!
      expect(inertia).to have_props(
        errors: { receipt: [ I18n.t("activerecord.errors.models.payment.attributes.receipt.already_under_review") ] }
      )
    end

    it "returns not found when account_id is invalid or does not exist" do
      sign_in users(:admin), role: :admin

      expect {
        post admin_payments_path, params: {
          payment: { account_id: "invalid-id", receipt: receipt_upload }
        }
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/payments/:id/receipt" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    it "allows HR to access a receipt from its company account" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("company receipt"), filename: "receipt.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      get receipt_admin_payment_path(payment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("company receipt")
    end

    it "does not expose receipts from another company" do
      payment = other_company_account.payments.build(
        provider: other_company_account.provider,
        status: :submitted
      )
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      get receipt_admin_payment_path(payment)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!

      get receipt_admin_payment_path(payment)

      expect(response).to redirect_to(sign_in_path)
    end

    it "does not allow a consumer to access a company receipt" do
      payment = account.payments.build(provider: account.provider, status: :submitted)
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:one), role: :consumer

      get receipt_admin_payment_path(payment)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /admin/payments/:id" do
    let(:account) { accounts(:gogrow_tuviandita_current) }

    def payment_with_receipt(status:, rejection_reason: nil)
      payment = account.payments.build(provider: account.provider, status:, rejection_reason:)
      payment.receipt.attach(io: StringIO.new("receipt"), filename: "receipt.png", content_type: "image/png")
      payment.save!
      payment
    end

    it "removes a receipt under review" do
      payment = payment_with_receipt(status: :submitted)
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(-1)

      follow_redirect!
      expect(inertia).to have_flash(notice: I18n.t("flash.payment_receipt_removed"))
    end

    it "removes a rejected receipt" do
      payment = payment_with_receipt(status: :rejected, rejection_reason: "Comprobante ilegible")
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.to change(Payment, :count).by(-1)
    end

    it "does not remove an approved receipt" do
      payment = payment_with_receipt(status: :approved)
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment), headers: { "HTTP_REFERER" => admin_payments_url }
      }.not_to change(Payment, :count)

      expect(payment.reload).to be_approved
    end

    it "does not remove a receipt from another company" do
      payment = other_company_account.payments.build(
        provider: other_company_account.provider,
        status: :submitted
      )
      payment.receipt.attach(io: StringIO.new("private"), filename: "private.png", content_type: "image/png")
      payment.save!
      sign_in users(:admin), role: :admin

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      payment = payment_with_receipt(status: :submitted)

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "does not allow a consumer to remove a company receipt" do
      payment = payment_with_receipt(status: :submitted)
      sign_in users(:one), role: :consumer

      expect {
        delete admin_payment_path(payment)
      }.not_to change(Payment, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
