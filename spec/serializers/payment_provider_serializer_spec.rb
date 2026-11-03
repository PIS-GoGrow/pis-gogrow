# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentProviderSerializer do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }

  describe "#to_h" do
    context "when provider has complete bank information configured" do
      before do
        provider.update!(
          bank_name: "Banco Itaú",
          bank_account_number: "1951234",
          bank_account_holder: "Tu Vianda SRL"
        )
      end

      it "serializes id, name, home_delivery, and all bank details" do
        serialized = described_class.new(provider).to_h

        expect(serialized).to eq(
          "id" => provider.id,
          "name" => provider.user.name,
          "home_delivery" => true,
          "bank_name" => "Banco Itaú",
          "bank_account_number" => "1951234",
          "bank_account_holder" => "Tu Vianda SRL",
          "payment_details_complete" => true
        )
      end

      it "strictly excludes sensitive or unneeded fields such as tax_id, bank_account_type, and user_id" do
        serialized = described_class.new(provider).to_h

        expect(serialized).not_to have_key("tax_id")
        expect(serialized).not_to have_key("bank_account_type")
        expect(serialized).not_to have_key("user_id")
        expect(serialized).not_to have_key("order_deadline")
        expect(serialized).not_to have_key("onboarding_completed_at")
      end
    end

    context "when provider has nil bank information" do
      it "serializes nil bank fields cleanly without error" do
        serialized = described_class.new(provider).to_h

        expect(serialized).to eq(
          "id" => provider.id,
          "name" => provider.user.name,
          "home_delivery" => true,
          "bank_name" => nil,
          "bank_account_number" => nil,
          "bank_account_holder" => nil,
          "payment_details_complete" => false
        )
      end
    end

    context "when provider has partial bank details" do
      before do
        provider.update!(
          bank_name: "BROU",
          bank_account_number: nil,
          bank_account_holder: nil
        )
      end

      it "serializes present attributes while leaving unset ones as nil" do
        serialized = described_class.new(provider).to_h

        expect(serialized["bank_name"]).to eq("BROU")
        expect(serialized["bank_account_number"]).to be_nil
        expect(serialized["bank_account_holder"]).to be_nil
      end
    end

    context "when provider has special characters and unusual data in bank fields" do
      before do
        provider.update!(
          bank_name: "Banco Santander - Sucursal 01 / Cta Cte",
          bank_account_number: "0012-345678/90 (CA$)",
          bank_account_holder: "María & José S.A. — Gastronomía"
        )
      end

      it "preserves unicode characters, punctuation, and formatting accurately" do
        serialized = described_class.new(provider).to_h

        expect(serialized["bank_name"]).to eq("Banco Santander - Sucursal 01 / Cta Cte")
        expect(serialized["bank_account_number"]).to eq("0012-345678/90 (CA$)")
        expect(serialized["bank_account_holder"]).to eq("María & José S.A. — Gastronomía")
      end
    end
  end
end
