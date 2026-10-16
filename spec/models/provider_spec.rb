# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider, type: :model do
  fixtures :providers

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
        bank_account_type: "savings",
        bank_account_number: "001234567-00001",
        bank_account_holder: "Tu Vianda SRL",
        tax_id: "212345670012"
      }
    end

    it "es válido con todos los datos requeridos y formatos correctos" do
      provider.assign_attributes(valid_attributes)

      expect(provider.valid?(:payment_details)).to be true
    end

    it "requiere presencia de todos los campos en el contexto de cobro" do
      provider.assign_attributes(
        bank_name: nil,
        bank_account_type: nil,
        bank_account_number: nil,
        bank_account_holder: nil,
        tax_id: nil
      )

      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:bank_name]).to be_present
      expect(provider.errors[:bank_account_type]).to be_present
      expect(provider.errors[:bank_account_number]).to be_present
      expect(provider.errors[:bank_account_holder]).to be_present
      expect(provider.errors[:tax_id]).to be_present
    end

    it "valida el formato de tax_id (acepta CI de 7 u 8 dígitos o RUT de 12 dígitos)" do
      provider.assign_attributes(valid_attributes.merge(tax_id: "1234567"))
      expect(provider.valid?(:payment_details)).to be true

      provider.assign_attributes(valid_attributes.merge(tax_id: "12345678"))
      expect(provider.valid?(:payment_details)).to be true

      provider.assign_attributes(valid_attributes.merge(tax_id: "212345670012"))
      expect(provider.valid?(:payment_details)).to be true

      provider.assign_attributes(valid_attributes.merge(tax_id: "12345"))
      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:tax_id]).to be_present

      provider.assign_attributes(valid_attributes.merge(tax_id: "1234567890123"))
      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:tax_id]).to be_present
    end

    it "valida el formato de bank_account_number (solo dígitos, guiones o espacios de 4 a 30 caracteres)" do
      provider.assign_attributes(valid_attributes.merge(bank_account_number: "123"))
      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:bank_account_number]).to be_present

      provider.assign_attributes(valid_attributes.merge(bank_account_number: "1234ABCD"))
      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:bank_account_number]).to be_present

      provider.assign_attributes(valid_attributes.merge(bank_account_number: "1" * 31))
      expect(provider.valid?(:payment_details)).to be false
      expect(provider.errors[:bank_account_number]).to be_present
    end

    it "no aplica las validaciones de cobro fuera del contexto :payment_details" do
      provider.assign_attributes(
        bank_name: nil,
        bank_account_type: nil,
        bank_account_number: nil,
        bank_account_holder: nil,
        tax_id: nil
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
      provider.bank_account_number = "  001234567-00001  "
      provider.bank_account_holder = "  Tu Vianda SRL  "

      expect(provider.bank_name).to eq("BROU")
      expect(provider.bank_account_number).to eq("001234567-00001")
      expect(provider.bank_account_holder).to eq("Tu Vianda SRL")
    end
  end
end

# == Schema Information
#
# Table name: providers
#
#  id                      :bigint           not null, primary key
#  bank_account_holder     :string
#  bank_account_number     :string
#  bank_account_type       :integer
#  bank_name               :string
#  home_delivery           :boolean          default(TRUE), not null
#  onboarding_completed_at :datetime
#  order_deadline          :time
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tax_id                  :string
#  user_id                 :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
