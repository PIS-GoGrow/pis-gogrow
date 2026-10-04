# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SpecialSubsidies", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }
  let(:company) { companies(:gogrow) }
  let(:params) do
    {
      special_subsidy: {
        name: "2 años",
        subsidy_percentage: 25,
        applies_to_all: false,
        consumer_ids: [ consumers(:one).id ],
        condition: { type: "seniority", min_years: 2 }
      }
    }
  end

  before { sign_in admin_user, role: :admin }

  def create_special_subsidy
    company.benefit_configurations.new(created_by: admin_user).tap do |configuration|
      configuration.save_special_subsidy(
        by: admin_user, name: "Cumpleaños", subsidy_percentage: 10, applies_to_all: true, consumer_ids: [],
        condition: { type: "birthday", limit: 1, validity_amount: 5, validity_unit: "days" }
      )
    end
  end

  describe "GET /admin/benefit_configurations" do
    it "expone los subsidios especiales activos y los empleados de la compañía" do
      special = create_special_subsidy
      deactivated = create_special_subsidy.tap { it.deactivate!(by: admin_user) }

      get admin_benefit_configurations_path

      ids = inertia.props[:special_subsidies].pluck(:id)
      expect(ids).to include(special.id)
      expect(ids).not_to include(deactivated.id, benefit_configurations(:monthly).id)
      expect(inertia.props[:special_subsidies].find { it[:id] == special.id }).to include(
        name: "Cumpleaños", subsidy_percentage: 10, applies_to_all: true,
        condition: include(type: "birthday", limit: 1, validity_amount: 5, validity_unit: "days")
      )
      expect(inertia.props[:employees]).to contain_exactly(
        { id: consumers(:other).id, name: "Other Consumer User", short_name: "Other U." },
        { id: consumers(:one).id, name: "Test User", short_name: "Test U." }
      )
    end
  end

  describe "POST /admin/special_subsidies" do
    it "crea el subsidio especial para los empleados elegidos" do
      expect { post admin_special_subsidies_path, params: }.to change(BenefitConfiguration, :count).by(1)

      expect(response).to redirect_to(admin_benefit_configurations_path)
      configuration = BenefitConfiguration.last
      expect(configuration).to have_attributes(name: "2 años", subsidy_percentage: 25, applies_to_all: false, company:, created_by: admin_user)
      expect(configuration.consumers).to eq([ consumers(:one) ])
      expect(configuration.benefit_rules.sole).to have_attributes(type: "SeniorityBenefit", min_years: 2)
      expect(configuration.benefit_configuration_changes.sole).to have_attributes(action: "created", user: admin_user)
    end

    it "devuelve los errores con los nombres de los campos del formulario" do
      params[:special_subsidy].merge!(name: "", consumer_ids: [], condition: { type: "birthday", limit: 0, validity_amount: 4, validity_unit: "months" })

      expect { post admin_special_subsidies_path, params: }.not_to change(BenefitConfiguration, :count)

      follow_redirect!
      expect(inertia.props[:errors].keys).to include("name", "consumer_ids", "limit", "validity_amount")
    end

    it "no acepta empleados de otra compañía" do
      other_company = Company.create!(name: "Otra", address: "Calle 1")
      params[:special_subsidy][:consumer_ids] = [ Consumer.create!(company: other_company, user: users(:two)).id ]

      expect { post admin_special_subsidies_path, params: }.not_to change(BenefitConfiguration, :count)
    end

    it "responde 400 sin la clave special_subsidy" do
      post admin_special_subsidies_path, params: { unexpected: "x" }

      expect(response).to have_http_status(:bad_request)
    end

    it "redirige a un consumidor sin crear nada" do
      sign_in users(:one), role: :consumer

      expect { post admin_special_subsidies_path, params: }.not_to change(BenefitConfiguration, :count)
      expect(response).to redirect_to(root_path)
    end

    it "redirige a un proveedor sin crear nada" do
      sign_in users(:provider_user), role: :provider

      expect { post admin_special_subsidies_path, params: }.not_to change(BenefitConfiguration, :count)
      expect(response).to redirect_to(root_path)
    end

    it "manda a iniciar sesión sin una sesión activa" do
      sign_out

      post admin_special_subsidies_path, params: params

      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe "PATCH /admin/special_subsidies/:id" do
    it "modifica el subsidio y audita el cambio" do
      special = create_special_subsidy

      patch admin_special_subsidy_path(special), params: params

      expect(response).to redirect_to(admin_benefit_configurations_path)
      expect(special.reload).to have_attributes(name: "2 años", subsidy_percentage: 25, applies_to_all: false)
      expect(special.benefit_rules.sole).to be_a(SeniorityBenefit)
      expect(special.benefit_configuration_changes.map(&:action)).to eq(%w[created updated])
    end

    it "no permite editar el subsidio base" do
      patch admin_special_subsidy_path(benefit_configurations(:monthly)), params: params

      expect(response).to have_http_status(:not_found)
    end

    it "no permite editar un subsidio de otra compañía" do
      other_company = Company.create!(name: "Otra", address: "Calle 1")
      foreign = other_company.benefit_configurations.new(created_by: admin_user)
      foreign.save_special_subsidy(by: admin_user, name: "X", subsidy_percentage: 5, applies_to_all: true, consumer_ids: [], condition: { type: "seniority", min_years: 1 })

      patch admin_special_subsidy_path(foreign), params: params

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /admin/special_subsidies/:id" do
    it "desactiva el subsidio en lugar de borrarlo" do
      special = create_special_subsidy

      expect { delete admin_special_subsidy_path(special) }.not_to change(BenefitConfiguration, :count)

      expect(response).to redirect_to(admin_benefit_configurations_path)
      expect(special.reload.deactivated_at).to be_present
      expect(special.benefit_configuration_changes.last).to be_deactivated
    end

    it "redirige a un consumidor sin desactivar nada" do
      special = create_special_subsidy
      sign_in users(:one), role: :consumer

      delete admin_special_subsidy_path(special)

      expect(response).to redirect_to(root_path)
      expect(special.reload.deactivated_at).to be_nil
    end
  end
end
