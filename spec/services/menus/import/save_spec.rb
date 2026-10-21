# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Save do
  fixtures :users, :providers, :menus, :menu_option_groups, :schedules

  let(:provider) { providers(:tuviandita) }
  let(:template) { Rails.root.join("public/plantillas/menu.csv") }
  let(:next_monday) { Date.current.next_week(:monday) }

  def save(path = template)
    plan = Menus::Import::Plan.new(provider:, path:).tap(&:call)
    described_class.new(provider:, plan:, by: users(:provider_user)).tap(&:call)
  end

  it "crea los platos que el proveedor no tenía, con sus grupos de opciones" do
    expect { save }.to change { provider.menus.saved.count }.by(2)

    menu = provider.menus.saved.find_by!(name: "Sorrentinos")
    expect(menu.price).to eq(380)
    expect(menu.description).to eq("Sorrentinos caseros con salsa a elección")
    expect(menu.option_groups.map { [ it.name, it.options, it.required, it.limit ] }).to eq([
      [ "Relleno", [ "ricota y nuez", "jamón y queso" ], true, 1 ],
      [ "Salsa", [ "filetto", "bolognesa", "crema" ], false, 1 ]
    ])
  end

  it "programa cada plato en los días que la planilla marcó" do
    save

    agenda = provider.menus.saved.find_by!(name: "Sorrentinos").current_agenda
    expect(agenda).to have_attributes(weekdays: [ 2, 4 ], starts_on: next_monday, ends_on: nil, amount: 15)
  end

  it "actualiza el plato que ya estaba guardado en lugar de duplicarlo" do
    save

    expect(menus(:milanesa).reload).to have_attributes(
      price: 320,
      description: "Milanesa con guarnición de papas",
      modified_by: users(:provider_user)
    )
    expect(provider.menus.saved.where(name: "Milanesa con papas fritas").count).to eq(1)
  end

  it "le deja al plato que se actualiza los grupos de la planilla" do
    menu = provider.menus.create!(
      name: "Sorrentinos", description: "Con salsa", price: 300,
      option_groups_attributes: [
        { name: "Salsa", options: [ "Filetto" ], limit: 1 },
        { name: "Postre", options: [ "Flan" ], limit: 1 }
      ]
    )
    salsa = menu.option_groups.find_by!(name: "Salsa")

    save

    groups = menu.reload.option_groups.order(:name)
    expect(groups.map(&:name)).to eq(%w[Relleno Salsa])
    # El grupo que ya existía conserva su id: los pedidos hechos siguen
    # cruzando la elección del empleado con el grupo.
    expect(groups.find_by(name: "Salsa")).to have_attributes(id: salsa.id, options: [ "filetto", "bolognesa", "crema" ])
  end

  it "no guarda nada si una fila falla al guardarse" do
    allow(Menus::Create).to receive(:new).and_wrap_original do |original, **arguments|
      original.call(**arguments).tap do |service|
        next unless arguments[:attributes][:name] == "Ensalada César"

        allow(service).to receive(:call) { service.errors.add(:base, "sin stock") && false }
      end
    end

    importer = nil
    expect { importer = save }.not_to change { Menu.count }
    expect(importer.errors).to eq(11 => [ "sin stock" ])
  end

  it "no guarda nada si el plan tiene errores" do
    path = Rails.root.join("tmp", "incompleto.csv")
    File.write(path, "nombre,descripcion,precio,cupo,lunes\nMilanesa,Con papas,,20,x\n")

    expect { save(path) }.not_to change { Menu.count }
  end
end
