# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer Accounts", type: :request do
  fixtures :users, :consumers, :companies, :providers, :accounts, :admins, :menus, :schedules, :benefits

  let(:consumer_user) { users(:one) }
  let(:other_consumer_user) { users(:other_consumer_user) }
  let(:provider_user) { users(:provider_user) }
  let(:admin_user) { users(:admin) }
  let(:provider) { providers(:tuviandita) }
  let(:other_provider) { providers(:office_provider) }

  describe "GET /payments (accounts_path)" do
    context "when consumer is signed in" do
      before do
        sign_in(consumer_user, role: :consumer)
      end

      it "renders 200 OK and consumer/accounts/index component via GET /payments" do
        get "/payments"

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("consumer/accounts/index")
      end

      it "renders 200 OK and consumer/accounts/index component via accounts_path helper" do
        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("consumer/accounts/index")
      end

      it "counts the monthly allowance like every other screen, not the meals ordered" do
        Order.create!(
          consumer: consumers(:one), schedule: schedules(:today), amount: 3, price: 900,
          address: "18 de Julio 1006", delivery_method: :office, status: :confirmed
        ).apply_benefit! benefits(:monthly), 2

        get accounts_path

        expect(inertia).to have_props(benefit_used: 2, benefit_available: 20)
      end

      it "returns 404 for legacy route /pagos" do
        get "/pagos"

        expect(response).to have_http_status(:not_found)
      end

      it "includes provider bank details in props[:providers] when configured" do
        provider.update!(
          bank_name: "Banco Itaú",
          bank_account_number: "1951234",
          bank_account_holder: "Tu Vianda SRL"
        )

        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props { |props|
          p = props.deep_symbolize_keys
          serialized = p[:providers].find { |pr| pr[:id] == provider.id }
          serialized[:bank_name] == "Banco Itaú" &&
            serialized[:bank_account_number] == "1951234" &&
            serialized[:bank_account_holder] == "Tu Vianda SRL" &&
            serialized[:name] == provider.user.name &&
            serialized[:home_delivery] == true
        }
      end

      it "serializes nil bank fields for providers without configured bank details" do
        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props { |props|
          p = props.deep_symbolize_keys
          serialized = p[:providers].find { |pr| pr[:id] == other_provider.id }
          serialized[:bank_name].nil? &&
            serialized[:bank_account_number].nil? &&
            serialized[:bank_account_holder].nil?
        }
      end

      it "strictly excludes tax_id (RUT), bank_account_type, and user_id from props[:providers]" do
        provider.update!(
          tax_id: "219999990019",
          bank_account_type: 1,
          bank_name: "Banco República",
          bank_account_number: "001-987654",
          bank_account_holder: "Viandas SRL"
        )

        get accounts_path

        expect(response).to have_http_status(:ok)
        all_keys = inertia.props[:providers].flat_map { |p| p.keys.map(&:to_s) }
        expect(all_keys).not_to include("tax_id", "bank_account_type", "user_id", "order_deadline")
      end
    end

    describe "Mandatory Edge Case 1: Interface Bypass" do
      before do
        sign_in(consumer_user, role: :consumer)
      end

      it "safely handles invalid query params tampering without crashing and defaults history to false" do
        get accounts_path, params: { type: "malicious_script_injection" }
        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props(history: false)

        get accounts_path, params: { type: [ "array", "injection" ] }
        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props(history: false)
      end

      it "correctly resolves history to true when type is history" do
        get accounts_path, params: { type: "history" }
        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props(history: true)
      end

      it "prevents direct show endpoint access to another consumer's account returning 404" do
        other_account = accounts(:other_tuviandita_current)

        get account_path(other_account), headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when accessing a non-existent account ID" do
        get "/accounts/99999999", headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "Mandatory Edge Case 2: Unexpected Data Types in Bank Details" do
      before do
        sign_in(consumer_user, role: :consumer)
      end

      it "safely serializes bank fields containing special characters and symbols" do
        provider.update!(
          bank_name: "Banco Santander - Sucursal 01 / Cta Cte",
          bank_account_number: "0012-345678/90 (CA$)",
          bank_account_holder: "María & José S.A. — Gastronomía"
        )

        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props { |props|
          p = props.deep_symbolize_keys
          serialized = p[:providers].find { |pr| pr[:id] == provider.id }
          serialized[:bank_name] == "Banco Santander - Sucursal 01 / Cta Cte" &&
            serialized[:bank_account_number] == "0012-345678/90 (CA$)" &&
            serialized[:bank_account_holder] == "María & José S.A. — Gastronomía"
        }
      end

      it "safely serializes partial bank details where only bank_name is provided" do
        provider.update!(
          bank_name: "BROU",
          bank_account_number: nil,
          bank_account_holder: nil
        )

        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props { |props|
          p = props.deep_symbolize_keys
          serialized = p[:providers].find { |pr| pr[:id] == provider.id }
          serialized[:bank_name] == "BROU" &&
            serialized[:bank_account_number].nil? &&
            serialized[:bank_account_holder].nil?
        }
      end
    end

    describe "Mandatory Edge Case 3: Role Access Control" do
      it "redirects unauthenticated users to sign in with alert flash" do
        get accounts_path

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq(I18n.t("flash.not_signed_in"))
      end

      it "blocks providers from accessing GET /payments, redirecting to root_path with alert flash" do
        sign_in(provider_user, role: :provider)

        get accounts_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end

      it "blocks admins from accessing GET /payments, redirecting to root_path with alert flash" do
        sign_in(admin_user, role: :admin)

        get accounts_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end

      it "blocks providers from accessing GET /accounts/:id, redirecting to root_path with alert flash" do
        sign_in(provider_user, role: :provider)
        account = accounts(:one_tuviandita_current)

        get account_path(account), headers: { "ACCEPT" => "application/json" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end

      it "blocks admins from accessing GET /accounts/:id, redirecting to root_path with alert flash" do
        sign_in(admin_user, role: :admin)
        account = accounts(:one_tuviandita_current)

        get account_path(account), headers: { "ACCEPT" => "application/json" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
      end
    end

    describe "Mandatory Edge Case 4: 422 / Database Integrity" do
      it "renders cleanly when consumer has zero accounts and zero debt" do
        consumers(:other).accounts.destroy_all

        sign_in(other_consumer_user, role: :consumer)

        get accounts_path

        expect(response).to have_http_status(:ok)
        expect(inertia).to have_props { |props|
          p = props.deep_symbolize_keys
          p[:total_debt].to_d.zero? &&
            p[:current_month_debt].to_d.zero? &&
            p[:benefit_used] == 0 &&
            p[:accounts].empty?
        }
      end

      it "rejects unsupported HTTP methods on /payments and /accounts/:id returning 404" do
        sign_in(consumer_user, role: :consumer)
        account = accounts(:one_tuviandita_current)

        post "/payments"
        expect(response).to have_http_status(:not_found)

        patch "/payments"
        expect(response).to have_http_status(:not_found)

        delete "/payments"
        expect(response).to have_http_status(:not_found)

        post account_path(account)
        expect(response).to have_http_status(:not_found)
      end

      it "tolerates unexpected data types and invalid values in query parameters" do
        sign_in(consumer_user, role: :consumer)

        get accounts_path, params: { type: "invalid_filter", unexpected: { nested: "payload" } }

        expect(response).to have_http_status(:ok)
        expect(inertia).to render_component("consumer/accounts/index")
      end

      it "returns 404 when requesting a non-existent or malformed account ID" do
        sign_in(consumer_user, role: :consumer)

        get account_path(id: 999_999)

        expect(response).to have_http_status(:not_found)
      end

      it "prevents accessing an account belonging to another consumer returning 404" do
        sign_in(consumer_user, role: :consumer)
        other_account = accounts(:other_tuviandita_current)

        get account_path(other_account)

        expect(response).to have_http_status(:not_found)
      end

      it "counts both pending and confirmed orders but ignores cancelled orders in benefit_used prop" do
        sign_in(consumer_user, role: :consumer)
        schedule = schedules(:today)

        # 1 confirmed order with 2 subsidized meals
        Order.create!(
          consumer: consumers(:one), schedule:, amount: 2, price: 600,
          address: "18 de Julio 1006", delivery_method: :office, status: :confirmed
        ).apply_benefit! benefits(:monthly), 2

        # 1 pending order with 1 subsidized meal
        Order.create!(
          consumer: consumers(:one), schedule:, amount: 1, price: 300,
          address: "18 de Julio 1006", delivery_method: :office, status: :pending
        ).apply_benefit! benefits(:monthly), 1

        # 1 cancelled order with 3 subsidized meals (must NOT be counted)
        Order.create!(
          consumer: consumers(:one), schedule:, amount: 3, price: 900,
          address: "18 de Julio 1006", delivery_method: :office, status: :cancelled
        ).apply_benefit! benefits(:monthly), 3

        get accounts_path

        expect(inertia).to have_props(benefit_used: 3, benefit_available: 20)
      end
    end
  end

  describe "Access control by role for /payments" do
    it "redirects an unauthenticated visitor to the sign in page" do
      get accounts_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a user with provider role to the root path with an alert" do
      sign_in(users(:provider_user), role: :provider)

      get accounts_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end

    it "redirects a user with admin role to the root path with an alert" do
      sign_in(users(:admin), role: :admin)

      get accounts_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end
  end
end
