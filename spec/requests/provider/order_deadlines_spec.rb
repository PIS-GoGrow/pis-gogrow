# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::OrderDeadlines", type: :request do
  fixtures :users, :providers, :admins

  let(:provider) { providers(:tuviandita) }
  let(:previous_deadline) { "10:00" }

  before { provider.update!(order_deadline: previous_deadline) }

  def deadline_of(provider)
    provider.reload.order_deadline&.strftime("%H:%M")
  end

  describe "PATCH /provider/order_deadline" do
    it "redirects to sign in without a session" do
      patch provider_order_deadline_path, params: { order_deadline: "18:30" }

      expect(response).to redirect_to(provider_sign_in_path)
      expect(deadline_of(provider)).to eq(previous_deadline)
    end

    it "redirects a consumer to the home page without touching any deadline" do
      sign_in users(:one), role: :consumer

      patch provider_order_deadline_path, params: { order_deadline: "18:30" }

      expect(response).to redirect_to(root_path)
      expect(deadline_of(provider)).to eq(previous_deadline)
    end

    it "redirects an admin to the home page without touching any deadline" do
      sign_in users(:admin), role: :admin

      patch provider_order_deadline_path, params: { order_deadline: "18:30" }

      expect(response).to redirect_to(root_path)
      expect(deadline_of(provider)).to eq(previous_deadline)
    end

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "saves the new deadline and shows it back in the operational settings" do
        patch provider_order_deadline_path, params: { order_deadline: "18:30" }

        expect(response).to redirect_to(provider_operational_settings_path)
        expect(deadline_of(provider)).to eq("18:30")
        follow_redirect!
        expect(inertia).to render_component("provider/operational_settings/show")
        expect(inertia).to have_props(provider: { order_deadline: "18:30" })
      end

      it "marks order_deadline_configured_at upon successful save" do
        provider.update_column(:order_deadline_configured_at, nil)

        expect do
          patch provider_order_deadline_path, params: { order_deadline: "18:30" }
        end.to change { provider.reload.order_deadline_configured_at }.from(nil)
      end

      it "preserves existing order_deadline_configured_at timestamp (idempotent)" do
        existing_timestamp = 2.days.ago.change(usec: 0)
        provider.update_column(:order_deadline_configured_at, existing_timestamp)

        patch provider_order_deadline_path, params: { order_deadline: "18:30" }

        expect(provider.reload.order_deadline_configured_at).to eq(existing_timestamp)
      end

      it "only changes the signed-in provider's deadline" do
        others = providers(:endulzate, :office_provider)
        others.each { |other| other.update!(order_deadline: "11:00") }

        expect do
          patch provider_order_deadline_path, params: { order_deadline: "18:30" }
        end.not_to(change { others.map { |other| deadline_of(other) } })
      end

      %w[00:00 23:59].each do |boundary|
        it "accepts the boundary value #{boundary}" do
          patch provider_order_deadline_path, params: { order_deadline: boundary }

          expect(deadline_of(provider)).to eq(boundary)
        end
      end

      [ "", "   " ].each do |blank|
        it "clears the deadline when it is sent as #{blank.inspect}" do
          patch provider_order_deadline_path, params: { order_deadline: blank }

          expect(response).to redirect_to(provider_operational_settings_path)
          expect(deadline_of(provider)).to be_nil
          follow_redirect!
          expect(inertia).to have_props(provider: { order_deadline: nil })
        end
      end

      %w[25:00 24:00 23:60 9:30 12:5 18:30:00 abc -01:00].each do |invalid|
        it "rejects #{invalid.inspect} and keeps the previous deadline without marking timestamp" do
          provider.update_column(:order_deadline_configured_at, nil)

          patch provider_order_deadline_path, params: { order_deadline: invalid }

          expect(response).to redirect_to(provider_operational_settings_path)
          expect(deadline_of(provider)).to eq(previous_deadline)
          expect(provider.reload.order_deadline_configured_at).to be_nil
          follow_redirect!
          expect(inertia).to have_props(errors: { order_deadline: [ I18n.t("validations.invalid_order_deadline") ] })
        end
      end

      it "rejects integer deadline 9999 and leaves timestamp untouched" do
        provider.update_column(:order_deadline_configured_at, nil)

        patch provider_order_deadline_path, params: { order_deadline: 9999 }

        expect(response).to redirect_to(provider_operational_settings_path)
        expect(deadline_of(provider)).to eq(previous_deadline)
        expect(provider.reload.order_deadline_configured_at).to be_nil
        follow_redirect!
        expect(inertia).to have_props(errors: { order_deadline: [ I18n.t("validations.invalid_order_deadline") ] })
      end

      context "durante el onboarding" do
        before do
          provider.update!(onboarding_completed_at: nil)
          provider.update_column(:order_deadline_configured_at, nil)
        end

        it "guarda la hora sin ser desviado por el guard, marca timestamp y vuelve al paso 2 del onboarding" do
          expect do
            patch provider_order_deadline_path, params: { order_deadline: "18:30", onboarding: true }
          end.to change { provider.reload.order_deadline_configured_at }.from(nil)

          expect(response).to redirect_to(provider_onboarding_path(step: 2))
          expect(deadline_of(provider)).to eq("18:30")
        end

        it "redirecciona al paso 2 con errores de inertia y no marca timestamp si el deadline es inválido" do
          patch provider_order_deadline_path, params: { order_deadline: "25:00", onboarding: true }

          expect(response).to redirect_to(provider_onboarding_path(step: 2))
          expect(deadline_of(provider)).to eq(previous_deadline)
          expect(provider.reload.order_deadline_configured_at).to be_nil
          follow_redirect!
          expect(inertia).to have_props(errors: { order_deadline: [ I18n.t("validations.invalid_order_deadline") ] })
        end
      end
    end
  end
end
