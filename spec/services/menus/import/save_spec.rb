# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::Save do
  fixtures :users, :providers, :menus, :menu_option_groups, :schedules

  let(:provider) { providers(:tuviandita) }
  let(:next_monday) { Date.current.next_week(:monday) }

  # Una entrada como la manda la vista previa, ya revisada por el proveedor.
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

  def service(*entries)
    described_class.new(provider:, entries:, by: users(:provider_user))
  end

  def save(*entries) = service(*entries).tap(&:call)

  describe "los platos nuevos" do
    it "los crea con sus grupos de opciones" do
      groups = [
        { name: "Relleno", options: [ "ricota y nuez", "jamón y queso" ], required: true, limit: 1 },
        { name: "Salsa", options: [ "filetto", "crema" ], required: false, limit: 2 }
      ]

      expect { save(entry(option_groups: groups)) }.to change { provider.menus.saved.count }.by(1)

      menu = provider.menus.saved.find_by!(name: "Sorrentinos")
      expect(menu.price).to eq(380)
      expect(menu.option_groups.map { [ it.name, it.options, it.required, it.limit ] }).to eq([
        [ "Relleno", [ "ricota y nuez", "jamón y queso" ], true, 1 ],
        [ "Salsa", [ "filetto", "crema" ], false, 2 ]
      ])
    end

    it "los deja sin programar: la planilla no trae agenda" do
      save(entry)

      menu = provider.menus.saved.find_by!(name: "Sorrentinos")
      expect(menu.schedules).to be_empty
      expect(menu.current_agenda).to be_nil
    end

    it "los programa si el proveedor les puso agenda al editarlos" do
      agenda = { mode: "weekly", weekdays: [ 2, 4 ], starts_on: next_monday.to_s, ends_on: nil }

      save(entry(agenda:))

      expect(provider.menus.saved.find_by!(name: "Sorrentinos").current_agenda)
        .to have_attributes(weekdays: [ 2, 4 ], starts_on: next_monday, ends_on: nil)
    end

    it "crea un plato que se llama igual que uno guardado, si eso fue lo que eligió" do
      expect { save(entry(name: "Milanesa con papas fritas")) }
        .to change { provider.menus.saved.where(name: "Milanesa con papas fritas").count }.by(1)
    end
  end

  describe "los platos que se actualizan" do
    let(:milanesa) { menus(:milanesa) }

    def update(**values)
      save(entry(action: "update", menu_id: milanesa.id, name: milanesa.name, **values))
    end

    it "pisa el plato guardado en lugar de duplicarlo" do
      expect { update(description: "Con guarnición de papas", price: "420") }
        .not_to change { provider.menus.saved.count }

      expect(milanesa.reload).to have_attributes(price: 420, description: "Con guarnición de papas")
    end

    it "le devuelve la agenda que ya tenía cuando la vista previa la manda igual" do
      milanesa.agendas.create!(weekdays: [ 1, 3 ], starts_on: next_monday)
      agenda = { mode: "weekly", weekdays: [ 1, 3 ], starts_on: next_monday.to_s, ends_on: nil }

      update(agenda:)

      expect(milanesa.reload.current_agenda)
        .to have_attributes(weekdays: [ 1, 3 ], starts_on: next_monday)
    end

    it "actualiza los grupos de opciones conservando el id de los que ya existían" do
      group = milanesa.option_groups.create!(name: "Cocción", options: [ "A punto", "Cocida" ], required: true, limit: 1)
      new_groups = [
        { name: "Cocción", options: [ "Jugosa", "Cocida" ], required: true, limit: 1 },
        { name: "Guarnición", options: [ "Papas", "Puré" ], required: false, limit: 1 }
      ]

      update(option_groups: new_groups)

      milanesa.reload
      expect(milanesa.option_groups.find_by(name: "Cocción").id).to eq(group.id)
      expect(milanesa.option_groups.find_by(name: "Cocción").options).to eq([ "Jugosa", "Cocida" ])
      expect(milanesa.option_groups.find_by(name: "Guarnición")).to be_present
    end

    it "no toca un plato de otro proveedor" do
      expect { save(entry(action: "update", menu_id: menus(:sorrentinos).id)) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "cuando una fila falla al guardar" do
    it "no escribe ninguna y devuelve el error en la tarjeta que lo produjo" do
      failed = service(entry(key: "a"), entry(key: "b", name: "Tarta", price: "0"))

      expect { expect(failed.call).to be(false) }.not_to change { provider.menus.saved.count }
      expect(failed.errors.keys).to eq([ "b" ])
    end
  end

  it "no hace nada con una lista vacía" do
    expect(service.call).to be(false)
  end
end
