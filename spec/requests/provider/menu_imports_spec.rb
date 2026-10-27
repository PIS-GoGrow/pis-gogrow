# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::MenuImports", type: :request do
  fixtures :users, :providers, :menus, :menu_option_groups

  let(:provider_user) { users(:provider_user) }

  def upload(contents = nil, filename: "menu.csv")
    path = contents ? write(contents) : Rails.root.join("public/plantillas/menu.csv")
    Rack::Test::UploadedFile.new(path, "text/csv", original_filename: filename)
  end

  def write(contents)
    Rails.root.join("tmp", "subida.csv").tap { File.write(it, contents) }
  end

  before { sign_in provider_user, role: :provider }

  describe "GET /proveedor/importar-platos" do
    it "muestra las instrucciones, sin vista previa" do
      get provider_menu_import_path

      expect(inertia.component).to eq("provider/menu_imports/new")
      expect(inertia.props[:preview]).to be_nil
      expect(inertia.props[:template_path]).to eq("/plantillas/menu.csv")
    end

    it "no lo puede abrir un empleado" do
      sign_in users(:one), role: :consumer

      get provider_menu_import_path

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /proveedor/importar-platos" do
    it "muestra qué se va a importar sin tocar la base" do
      expect { post provider_menu_import_preview_path, params: { file: upload } }
        .not_to change { Menu.count }

      preview = inertia.props[:preview]
      expect(preview[:can_import]).to be(true)
      expect(preview[:filename]).to eq("menu.csv")
      expect(preview[:entries].map { it[:action] }).to eq(%w[update create create])
    end

    it "señala la fila con el error y no deja importar" do
      post provider_menu_import_preview_path, params: {
        file: upload("nombre,descripcion,precio,cupo,lunes\nMilanesa,Con papas,,20,x\n")
      }

      preview = inertia.props[:preview]
      expect(preview[:can_import]).to be(false)
      expect(preview[:entries].sole).to include(number: 2, errors: [ I18n.t("validations.menu_import.price") ])
    end

    it "avisa cuando el archivo no es una planilla" do
      post provider_menu_import_preview_path, params: { file: upload(filename: "menu.pdf") }

      expect(inertia.props[:preview][:error])
        .to eq(I18n.t("validations.menu_import.file.unsupported_format"))
    end

    it "no se cae si no llega ningún archivo" do
      post provider_menu_import_preview_path

      expect(inertia.props[:preview][:error])
        .to eq(I18n.t("validations.menu_import.file.unsupported_format"))
    end
  end

  describe "POST /proveedor/importar-platos/confirmar" do
    it "importa los platos y vuelve al menú" do
      expect { post provider_confirm_menu_import_path, params: { file: upload } }
        .to change { providers(:tuviandita).menus.saved.count }.by(2)

      expect(response).to redirect_to(schedules_path(tab: "saved"))
      expect(flash[:notice]).to eq(I18n.t("flash.menu_imported", count: 3))
    end

    it "no importa nada si la planilla tiene errores" do
      expect do
        post provider_confirm_menu_import_path, params: {
          file: upload("nombre,descripcion,precio,cupo,lunes\nTarta,De verdura,290,0,x\n")
        }
      end.not_to change { Menu.count }

      expect(inertia.props[:preview][:can_import]).to be(false)
    end

    it "maneja el intento de confirmación sin archivo o con parámetro inválido (bypass de interfaz)" do
      expect do
        post provider_confirm_menu_import_path, params: { file: "bypass_string" }
      end.not_to change { Menu.count }

      preview = inertia.props[:preview]
      expect(preview[:can_import]).to be(false)
      expect(preview[:error]).to eq(I18n.t("validations.menu_import.file.unsupported_format"))
    end

    it "mantiene la integridad en la base si falla el guardado de un plato y devuelve el error" do
      allow(Menus::Create).to receive(:new).and_wrap_original do |original, **arguments|
        original.call(**arguments).tap do |service|
          next unless arguments[:attributes][:name] == "Ensalada César"

          allow(service).to receive(:call) { service.errors.add(:base, "error de validación") && false }
        end
      end

      expect do
        post provider_confirm_menu_import_path, params: { file: upload }
      end.not_to change { Menu.count }

      preview = inertia.props[:preview]
      expect(preview[:can_import]).to be(false)
      failed_entry = preview[:entries].find { it[:name] == "Ensalada César" }
      expect(failed_entry[:errors]).to include("error de validación")
    end
  end

  describe "control de acceso por rol y estado" do
    context "sin iniciar sesión" do
      it "redirige al inicio de sesión" do
        sign_out

        get provider_menu_import_path
        expect(response).to redirect_to(provider_sign_in_path)

        post provider_menu_import_preview_path, params: { file: upload }
        expect(response).to redirect_to(provider_sign_in_path)

        post provider_confirm_menu_import_path, params: { file: upload }
        expect(response).to redirect_to(provider_sign_in_path)
      end
    end

    context "como admin" do
      it "no permite acceder y redirige" do
        sign_in users(:admin), role: :admin

        get provider_menu_import_path
        expect(response).to have_http_status(:redirect)

        post provider_menu_import_preview_path, params: { file: upload }
        expect(response).to have_http_status(:redirect)

        post provider_confirm_menu_import_path, params: { file: upload }
        expect(response).to have_http_status(:redirect)
      end
    end

    context "como consumer" do
      it "no permite previsualizar ni confirmar" do
        sign_in users(:one), role: :consumer

        post provider_menu_import_preview_path, params: { file: upload }
        expect(response).to have_http_status(:redirect)

        post provider_confirm_menu_import_path, params: { file: upload }
        expect(response).to have_http_status(:redirect)
      end
    end

    context "como proveedor sin onboarding completado" do
      it "redirige al wizard de onboarding" do
        providers(:tuviandita).update!(onboarding_completed_at: nil)

        get provider_menu_import_path
        expect(response).to redirect_to(provider_onboarding_path)

        post provider_menu_import_preview_path, params: { file: upload }
        expect(response).to redirect_to(provider_onboarding_path)

        post provider_confirm_menu_import_path, params: { file: upload }
        expect(response).to redirect_to(provider_onboarding_path)
      end
    end
  end
end
