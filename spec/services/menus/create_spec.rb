# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Create do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }
  let(:attributes) do
    { name: "Milanesa de pollo", description: "Con puré mixto", price: 340.0 }
  end

  before { travel_to Date.new(2030, 1, 9) } # Miércoles

  describe "#call" do
    context "con agenda de repetición semanal" do
      it "exige al menos un día de la semana y no persiste nada si está vacío" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: { mode: "weekly", starts_on: "2030-01-09", weekdays: [] }
        )

        expect do
          expect(service.call).to be(false)
        end.not_to change(Menu, :count)

        expect(service.errors[:agenda]).to include(I18n.t("validations.menu_agenda.invalid_weekdays"))
      end

      it "rechaza días fuera de lunes a viernes (1..5) como fines de semana o números inválidos" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: { mode: "weekly", starts_on: "2030-01-09", weekdays: [ 0, 6, 7 ] }
        )

        expect(service.call).to be(false)
        expect(service.errors[:agenda]).to include(I18n.t("validations.menu_agenda.invalid_weekdays"))
        expect(Menu.find_by(name: "Milanesa de pollo")).to be_nil
      end

      it "rechaza tipos de datos no numéricos que no mapeen a días válidos" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: { mode: "weekly", starts_on: "2030-01-09", weekdays: [ "invalido", "" ] }
        )

        expect(service.call).to be(false)
        expect(service.errors[:agenda]).to include(I18n.t("validations.menu_agenda.invalid_weekdays"))
      end

      it "persiste el plato, la agenda semanal y genera programaciones cuando los días son válidos" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: { mode: "weekly", starts_on: "2030-01-09", weekdays: [ 1, 3 ], amount: 5 }
        )

        expect do
          expect(service.call).to be(true)
        end.to change(provider.menus, :count).by(1)
          .and change(MenuAgenda, :count).by(1)
          .and change(Schedule, :count).by_at_least(1)

        menu = service.menu
        expect(menu.agendas.sole).to have_attributes(
          weekdays: [ 1, 3 ],
          starts_on: Date.new(2030, 1, 9),
          ends_on: nil,
          amount: 5
        )
      end
    end

    context "con agenda de rango personalizado" do
      it "exige al menos un día de la semana y no persiste nada si está vacío" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: {
            mode: "range",
            starts_on: "2030-01-10",
            ends_on: "2030-01-15",
            weekdays: []
          }
        )

        expect do
          expect(service.call).to be(false)
        end.not_to change(Menu, :count)

        expect(MenuAgenda.where(menu: provider.menus)).to be_empty

        expect(service.errors[:agenda]).to include(I18n.t("validations.menu_agenda.invalid_weekdays"))
      end

      it "rechaza rango cuando los días no pertenecen a 1..5" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: {
            mode: "range",
            starts_on: "2030-01-10",
            ends_on: "2030-01-15",
            weekdays: [ 6 ]
          }
        )

        expect(service.call).to be(false)
        expect(service.errors[:agenda]).to include(I18n.t("validations.menu_agenda.invalid_weekdays"))
      end

      it "crea el plato con agenda de rango cuando los días son válidos" do
        service = described_class.new(
          provider:,
          attributes:,
          agenda: {
            mode: "range",
            starts_on: "2030-01-10",
            ends_on: "2030-01-15",
            weekdays: [ 2, 4 ],
            amount: 4
          }
        )

        expect(service.call).to be(true)
        menu = service.menu
        expect(menu.agendas.sole).to have_attributes(
          starts_on: Date.new(2030, 1, 10),
          ends_on: Date.new(2030, 1, 15),
          weekdays: [ 2, 4 ],
          amount: 4
        )
      end
    end
  end
end
