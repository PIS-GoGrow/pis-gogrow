# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider, type: :model do
  fixtures :providers, :users

  describe "secciones de la cuenta" do
    let(:provider) { providers(:tuviandita) }

    it "marca todas las secciones como incompletas hasta configurarlas" do
      provider.update_columns(
        payment_details_configured_at: nil,
        order_deadline_configured_at: nil,
        deliveries_configured_at: nil,
        notifications_configured_at: nil
      )

      expect(provider.incomplete_sections).to contain_exactly(
        "payment_details", "operational_settings", "deliveries", "notifications"
      )
      expect(provider.completed_sections_count).to eq(0)
      expect(provider.total_sections_count).to eq(4)
    end

    it "marca una sección como completa al configurarla, aunque luego se vacíen los datos" do
      provider.update_column(:deliveries_configured_at, nil)
      expect(provider.incomplete_sections).to include("deliveries")

      provider.mark_section_configured!(:deliveries)

      expect(provider.incomplete_sections).not_to include("deliveries")
    end

    it "no re-marca una sección que ya estaba configurada" do
      provider.update_column(:payment_details_configured_at, 2.days.ago)

      expect { provider.mark_section_configured!(:payment_details) }
        .not_to(change { provider.reload.payment_details_configured_at })
    end

    it "actualiza el timestamp correspondiente a cada una de las 4 secciones" do
      provider.update_columns(
        payment_details_configured_at: nil,
        order_deadline_configured_at: nil,
        deliveries_configured_at: nil,
        notifications_configured_at: nil
      )

      expect { provider.mark_section_configured!(:payment_details) }
        .to change { provider.reload.payment_details_configured_at }.from(nil)
      expect { provider.mark_section_configured!(:operational_settings) }
        .to change { provider.reload.order_deadline_configured_at }.from(nil)
      expect { provider.mark_section_configured!(:deliveries) }
        .to change { provider.reload.deliveries_configured_at }.from(nil)
      expect { provider.mark_section_configured!(:notifications) }
        .to change { provider.reload.notifications_configured_at }.from(nil)
    end

    it "es idempotente en las 4 secciones y preserva los timestamps originales" do
      timestamps = {
        payment_details_configured_at: 4.days.ago.change(usec: 0),
        order_deadline_configured_at: 3.days.ago.change(usec: 0),
        deliveries_configured_at: 2.days.ago.change(usec: 0),
        notifications_configured_at: 1.day.ago.change(usec: 0)
      }
      provider.update_columns(timestamps)

      Provider::CONFIGURABLE_SECTIONS.each_key do |section|
        provider.mark_section_configured!(section)
      end

      provider.reload
      expect(provider.payment_details_configured_at).to eq(timestamps[:payment_details_configured_at])
      expect(provider.order_deadline_configured_at).to eq(timestamps[:order_deadline_configured_at])
      expect(provider.deliveries_configured_at).to eq(timestamps[:deliveries_configured_at])
      expect(provider.notifications_configured_at).to eq(timestamps[:notifications_configured_at])
    end

    it "lanza KeyError al recibir una clave de sección desconocida o inválida" do
      expect { provider.mark_section_configured!(:desconocida) }.to raise_error(KeyError)
      expect { provider.mark_section_configured!(:billing) }.to raise_error(KeyError)
      expect { provider.mark_section_configured!("desconocida") }.to raise_error(KeyError)
    end

    it "refleja el avance progresivo de 0/4 a 4/4 y vacía incomplete_sections al completar todas" do
      provider.update_columns(
        payment_details_configured_at: nil,
        order_deadline_configured_at: nil,
        deliveries_configured_at: nil,
        notifications_configured_at: nil
      )

      expect(provider.completed_sections_count).to eq(0)
      expect(provider.incomplete_sections).to contain_exactly(
        "payment_details", "operational_settings", "deliveries", "notifications"
      )

      provider.mark_section_configured!(:payment_details)
      expect(provider.completed_sections_count).to eq(1)

      provider.mark_section_configured!(:operational_settings)
      expect(provider.completed_sections_count).to eq(2)

      provider.mark_section_configured!(:deliveries)
      expect(provider.completed_sections_count).to eq(3)

      provider.mark_section_configured!(:notifications)
      expect(provider.completed_sections_count).to eq(4)
      expect(provider.incomplete_sections).to eq([])
    end
  end

  describe "#delivery_methods" do
    it "lists only office for an office-only provider" do
      expect(providers(:office_provider).delivery_methods).to eq([ "office" ])
    end

    it "lists every method when home delivery is on" do
      expect(providers(:tuviandita).delivery_methods).to eq(Order.delivery_methods.keys)
    end
  end

  describe "#home_delivery" do
    it "defaults to true for a new provider" do
      expect(described_class.new.home_delivery).to be true
    end

    it "persists false when disabling home delivery" do
      provider = providers(:tuviandita)
      provider.update!(home_delivery: false)

      expect(provider.reload.home_delivery).to be false
      expect(provider.delivery_methods).to eq([ "office" ])
    end

    it "raises NotNullViolation when home_delivery is set to nil (database integrity)" do
      provider = providers(:tuviandita)

      expect {
        provider.update_column(:home_delivery, nil)
      }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "#allows_delivery_method?" do
    it "is false for a method outside the provider policy" do
      expect(providers(:office_provider).allows_delivery_method?(:home)).to be false
      expect(providers(:office_provider).allows_delivery_method?("office")).to be true
    end

    it "is true for every method when home delivery is on" do
      expect(providers(:tuviandita).allows_delivery_method?(:office)).to be true
      expect(providers(:tuviandita).allows_delivery_method?(:home)).to be true
    end
  end

  describe "#payment_details_complete?" do
    let(:provider) { providers(:tuviandita) }

    it "is true with the bank, account details and beneficiary" do
      provider.assign_attributes(bank_name: "Santander", bank_account_details: "Cuenta: 1150260", beneficiary: "Tu Viandita S.A.")

      expect(provider.payment_details_complete?).to be true
    end

    it "is false while any of them is missing" do
      provider.assign_attributes(bank_name: "Santander", bank_account_details: "Cuenta: 1150260", beneficiary: nil)

      expect(provider.payment_details_complete?).to be false
    end

    it "is false when attributes are blank strings or whitespace" do
      provider.assign_attributes(bank_name: "   ", bank_account_details: "Cuenta: 1150260", beneficiary: "Tu Viandita S.A.")
      expect(provider.payment_details_complete?).to be false

      provider.assign_attributes(bank_name: "Santander", bank_account_details: "", beneficiary: "Tu Viandita S.A.")
      expect(provider.payment_details_complete?).to be false

      provider.assign_attributes(bank_name: "Santander", bank_account_details: "Cuenta: 1150260", beneficiary: "\t\n")
      expect(provider.payment_details_complete?).to be false
    end

    it "is false when all payment detail attributes are nil" do
      provider.assign_attributes(bank_name: nil, bank_account_details: nil, beneficiary: nil)

      expect(provider.payment_details_complete?).to be false
    end
  end

  describe "#order_deadline_passed_today?" do
    let(:provider) { providers(:tuviandita) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 2, 11, 30)) { example.run }
    end

    it "is false without a deadline" do
      provider.order_deadline = nil

      expect(provider.order_deadline_passed_today?).to be false
    end

    it "is false a minute before the deadline" do
      provider.order_deadline = Time.zone.parse("11:31")

      expect(provider.order_deadline_passed_today?).to be false
    end

    it "is true right at the deadline" do
      provider.order_deadline = Time.zone.parse("11:30")

      expect(provider.order_deadline_passed_today?).to be true
    end

    it "is true once the deadline has passed" do
      provider.order_deadline = Time.zone.parse("11:29")

      expect(provider.order_deadline_passed_today?).to be true
    end
  end

  describe "#response_deadline_passed_today?" do
    let(:provider) { providers(:tuviandita) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 2, 12, 30)) { example.run }
    end

    it "is false without a deadline" do
      provider.order_deadline = nil

      expect(provider.response_deadline_passed_today?).to be false
    end

    it "is false a minute before the half hour after the deadline" do
      provider.order_deadline = Time.zone.parse("12:01")

      expect(provider.response_deadline_passed_today?).to be false
    end

    it "is true half an hour after the deadline" do
      provider.order_deadline = Time.zone.parse("12:00")

      expect(provider.response_deadline_passed_today?).to be true
    end
  end

  describe "#seconds_until_order_deadline" do
    let(:provider) { providers(:tuviandita) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 2, 11, 30)) { example.run }
    end

    it "is nil without a deadline" do
      provider.order_deadline = nil

      expect(provider.seconds_until_order_deadline).to be_nil
    end

    it "counts the seconds left before the deadline" do
      provider.order_deadline = Time.zone.parse("11:31")

      expect(provider.seconds_until_order_deadline).to eq 60
    end

    it "is nil once the deadline has been reached" do
      provider.order_deadline = Time.zone.parse("11:30")

      expect(provider.seconds_until_order_deadline).to be_nil
    end

    it "is nil after the deadline has passed" do
      provider.order_deadline = Time.zone.parse("11:29")

      expect(provider.seconds_until_order_deadline).to be_nil
    end

    it "rounds up fractions of a second to ensure remaining time is not underestimated" do
      provider.order_deadline = Time.zone.parse("11:31")
      # El around hook ya fijó el tiempo en 11:30:00 (quedan 60s).
      # Si el deadline fuera en 11:30:01 (1 segundo después) y estamos en 11:30:00.2 (quedan 0.8s):
      provider.order_deadline = Time.zone.local(2026, 10, 2, 11, 30, 1)

      expect(provider.seconds_until_order_deadline).to eq 1
    end

    it "maintains consistency with order_deadline_passed_today? across the exact transition" do
      # Exactamente a la hora límite (11:30)
      provider.order_deadline = Time.zone.parse("11:30")
      expect(provider.order_deadline_passed_today?).to be true
      expect(provider.seconds_until_order_deadline).to be_nil

      # Un segundo después de la hora límite (11:30:01)
      provider.order_deadline = Time.zone.local(2026, 10, 2, 11, 30, 1)
      expect(provider.order_deadline_passed_today?).to be false
      expect(provider.seconds_until_order_deadline).to eq 1
    end
  end

  describe "#order_deadline_today" do
    let(:provider) { providers(:tuviandita) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 2, 8, 0)) { example.run }
    end

    it "is nil without a deadline" do
      provider.order_deadline = nil

      expect(provider.send(:order_deadline_today)).to be_nil
    end

    it "combines today's date with the configured deadline hour and minute" do
      provider.order_deadline = Time.zone.parse("14:45")

      expect(provider.send(:order_deadline_today)).to eq Time.zone.local(2026, 10, 2, 14, 45, 0)
    end
  end

  describe "#closed_on?" do
    let(:provider) { providers(:tuviandita) }
    let(:monday) { Date.new(2026, 10, 12) }

    around do |example|
      travel_to(Time.zone.local(2026, 10, 12, 9, 0)) { example.run }
    end

    it "is false without closures" do
      expect(provider.closed_on?(monday)).to be false
    end

    it "is true on every day of a closure, ends included" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect((monday + 1..monday + 3).map { provider.closed_on?(it) }).to all(be true)
    end

    it "is false the day before and the day after" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect(provider.closed_on?(monday)).to be false
      expect(provider.closed_on?(monday + 4)).to be false
    end

    it "only looks at its own closures" do
      providers(:endulzate).closures.create!(starts_on: monday + 1, ends_on: monday + 3, reason: "Vacaciones")

      expect(provider.closed_on?(monday + 2)).to be false
    end

    it "does not run a query per date once the closures are loaded" do
      provider.closures.create!(starts_on: monday + 1, ends_on: monday + 1, reason: "Feriado")
      loaded = described_class.includes(:closures).find(provider.id)

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        5.times { |day| loaded.closed_on?(monday + day) }
      end

      expect(queries).to be_empty
    end
  end

  describe "#onboarded?" do
    it "es falso cuando onboarding_completed_at es nil" do
      provider = providers(:tuviandita)
      provider.onboarding_completed_at = nil

      expect(provider.onboarded?).to be false
    end

    it "es verdadero cuando onboarding_completed_at está presente" do
      provider = providers(:tuviandita)
      provider.onboarding_completed_at = Time.current

      expect(provider.onboarded?).to be true
    end
  end

  describe "validaciones de datos de cobro (contexto :payment_details)" do
    let(:provider) { providers(:tuviandita) }
    let(:valid_attributes) do
      {
        bank_name: "BROU",
        bank_account_details: "Cuenta: 001234567-00001\nMoneda: UYU",
        beneficiary: "Tu Vianda SRL"
      }
    end

    it "es válido con todos los datos requeridos y formatos correctos" do
      provider.assign_attributes(valid_attributes)

      expect(provider.valid?(:payment_details)).to be true
    end

    it "requiere presencia de todos los campos en el contexto de cobro" do
      provider.assign_attributes(
        bank_name: nil,
        bank_account_details: nil,
        beneficiary: nil
      )

      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:bank_name]).to be_present
      expect(provider.errors[:bank_account_details]).to be_present
      expect(provider.errors[:beneficiary]).to be_present
    end

    it "acepta texto libre con múltiples líneas en los datos de la cuenta" do
      provider.assign_attributes(
        valid_attributes.merge(
          bank_account_details: "Transferencias desde otros bancos\nCuenta: UY00 1234 ABCD\nSucursal: 70 - Golf"
        )
      )

      expect(provider.valid?(:payment_details)).to be true
    end

    it "no aplica las validaciones de cobro fuera del contexto :payment_details" do
      provider.assign_attributes(
        bank_name: nil,
        bank_account_details: nil,
        beneficiary: nil
      )

      expect(provider.valid?).to be true
    end
  end

  describe "normalizaciones" do
    let(:provider) { providers(:tuviandita) }

    it "elimina caracteres no numéricos de tax_id" do
      provider.tax_id = " 21.234.567/0012 "

      expect(provider.tax_id).to eq("212345670012")
    end

    it "hace strip de espacios en blanco en campos bancarios" do
      provider.bank_name = "  BROU  "
      provider.bank_account_details = "  Cuenta: 001234567-00001\nMoneda: UYU  "
      provider.beneficiary = "  Tu Vianda SRL  "

      expect(provider.bank_name).to eq("BROU")
      expect(provider.bank_account_details).to eq("Cuenta: 001234567-00001\nMoneda: UYU")
      expect(provider.beneficiary).to eq("Tu Vianda SRL")
    end
  end
end

# == Schema Information
#
# Table name: providers
#
#  id                            :bigint           not null, primary key
#  bank_account_details          :text
#  bank_name                     :string
#  beneficiary                   :string
#  deliveries_configured_at      :datetime
#  home_delivery                 :boolean          default(TRUE), not null
#  notifications_configured_at   :datetime
#  onboarding_completed_at       :datetime
#  order_deadline                :time
#  order_deadline_configured_at  :datetime
#  payment_details_configured_at :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  tax_id                        :string
#  user_id                       :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
