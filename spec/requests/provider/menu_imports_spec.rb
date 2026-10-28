# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::MenuImports", type: :request do
  fixtures :users, :providers, :menus, :menu_option_groups

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }

  def upload(contents = nil, filename: "menu.csv")
    path = contents ? write(contents) : Rails.root.join("public/plantillas/menu.csv")
    Rack::Test::UploadedFile.new(path, "text/csv", original_filename: filename)
  end

  def write(contents)
    Rails.root.join("tmp", "subida.csv").tap { File.write(it, contents) }
  end

  # Una entrada como la manda la pantalla después de que el proveedor la revisó.
  def entry(**values)
    {
      key: "a",
      action: "create",
      name: "Sorrentinos",
      description: "Sorrentinos caseros",
      price: "380",
      option_groups: [],
      agenda: { mode: "none" },
      confirmed_orders: "keep"
    }.merge(values)
  end

  before { sign_in provider_user, role: :provider }

  describe "GET /proveedor/importar-platos" do
    it "muestra las instrucciones, sin vista previa" do
      get provider_menu_import_path

      expect(inertia.component).to eq("provider/menu_imports/new")
      expect(inertia.props[:preview]).to be_nil
      expect(inertia.props[:template_path]).to eq("/plantillas/menu.csv")
      expect(inertia.props[:formats]).to eq([ ".xlsx", ".xls", ".csv", ".ods" ])
    end

    it "trae los platos guardados, para cruzarlos por nombre con la planilla" do
      get provider_menu_import_path

      expect(inertia.props[:saved_menus].map { it[:name] })
        .to include("Milanesa con papas fritas")
    end

    it "no lo puede abrir un empleado" do
      sign_in users(:one), role: :consumer

      get provider_menu_import_path

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /proveedor/importar-platos" do
    it "muestra qué trae la planilla sin tocar la base" do
      expect { post provider_menu_import_preview_path, params: { file: upload } }
        .not_to change { Menu.count }

      preview = inertia.props[:preview]
      expect(preview[:filename]).to eq("menu.csv")
      expect(preview[:error]).to be_nil
      expect(preview[:entries].map { it[:name] })
        .to eq([ "Milanesa con papas fritas", "Sorrentinos", "Ensalada César" ])
    end

    it "señala la fila con el error pero deja pasar a las demás" do
      post provider_menu_import_preview_path, params: {
        file: upload("nombre,descripcion,precio\nMilanesa,Con papas,\nTarta,De verdura,290\n")
      }

      entries = inertia.props[:preview][:entries]
      expect(entries.first).to include(number: 2, errors: [ I18n.t("validations.menu_import.price") ])
      expect(entries.second[:errors]).to be_empty
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
    it "importa lo que el proveedor revisó y avisa cuántos platos entraron" do
      expect { post provider_confirm_menu_import_path, params: { entries: [ entry ] } }
        .to change { provider.menus.saved.count }.by(1)

      expect(inertia.props[:imported]).to eq("count" => 1)
      expect(inertia.props[:row_errors]).to be_empty
    end

    it "actualiza el plato guardado que el proveedor eligió actualizar" do
      milanesa = menus(:milanesa)
      params = { entries: [ entry(action: "update", menu_id: milanesa.id, name: milanesa.name, price: "420") ] }

      expect { post provider_confirm_menu_import_path, params: }
        .not_to change { provider.menus.saved.count }

      expect(milanesa.reload.price).to eq(420)
    end

    it "no deja actualizar el plato de otro proveedor" do
      params = { entries: [ entry(action: "update", menu_id: menus(:sorrentinos).id) ] }

      expect { post provider_confirm_menu_import_path, params: }.not_to change { Menu.count }

      expect(response).to have_http_status(:not_found)
    end

    it "devuelve el error a la tarjeta que lo produjo, sin escribir nada" do
      params = { entries: [ entry(key: "b", price: "0") ] }

      expect { post provider_confirm_menu_import_path, params: }.not_to change { Menu.count }

      expect(inertia.props[:row_errors].keys).to eq([ "b" ])
      expect(inertia.props[:imported]).to be_nil
    end

    it "no acepta más platos que los que entran en una planilla" do
      stub_const("Menus::Import::Sheet::MAX_ROWS", 1)

      post provider_confirm_menu_import_path, params: { entries: [ entry, entry(key: "b") ] }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
