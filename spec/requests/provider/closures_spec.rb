# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Closures", type: :request do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }
  let(:today) { Date.new(2026, 10, 12) }
  let(:params) { { starts_on: (today + 7).iso8601, ends_on: (today + 9).iso8601, reason: "Vacaciones" } }

  before { travel_to Time.zone.local(2026, 10, 12, 9, 0) }

  def create_closure(owner = provider, starts_on: today + 7, ends_on: today + 9, reason: "Vacaciones")
    owner.closures.create!(starts_on:, ends_on:, reason:)
  end

  def error_message(attribute, key)
    I18n.t("activerecord.errors.models.provider_closure.attributes.#{attribute}.#{key}")
  end

  describe "POST /provider/closures" do
    it "redirects to sign in without a session" do
      expect { post provider_closures_path, params: }.not_to change(ProviderClosure, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects a consumer to the home page" do
      sign_in users(:one), role: :consumer

      expect { post provider_closures_path, params: }.not_to change(ProviderClosure, :count)

      expect(response).to redirect_to(root_path)
    end

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "saves the closure for the signed-in provider and shows it back" do
        expect { post provider_closures_path, params: }.to change { provider.closures.count }.by(1)

        expect(response).to redirect_to(provider_operational_settings_path)
        expect(provider.closures.last).to have_attributes(starts_on: today + 7, ends_on: today + 9, reason: "Vacaciones")
        follow_redirect!
        expect(inertia).to render_component("provider/operational_settings/show")
        expect(inertia.props[:closures].pluck(:reason)).to eq([ "Vacaciones" ])
      end

      it "never saves it for another provider, whatever the params say" do
        expect do
          post provider_closures_path, params: params.merge(provider_id: providers(:endulzate).id)
        end.not_to change { providers(:endulzate).closures.count }
      end

      it "accepts a single day" do
        post provider_closures_path, params: params.merge(ends_on: params[:starts_on])

        expect(provider.closures.last).to have_attributes(starts_on: today + 7, ends_on: today + 7)
      end

      it "lets two providers close the same range" do
        create_closure(providers(:endulzate))

        expect { post provider_closures_path, params: }.to change { provider.closures.count }.by(1)
      end

      it "requires a reason" do
        expect { post provider_closures_path, params: params.merge(reason: "") }.not_to change(ProviderClosure, :count)

        expect(response).to redirect_to(provider_operational_settings_path)
        follow_redirect!
        expect(inertia).to have_props(errors: { reason: [ error_message(:reason, :blank) ] })
      end

      it "rejects a start in the past" do
        expect do
          post provider_closures_path, params: params.merge(starts_on: (today - 1).iso8601)
        end.not_to change(ProviderClosure, :count)

        follow_redirect!
        expect(inertia).to have_props(errors: { starts_on: [ error_message(:starts_on, :greater_than_or_equal_to) ] })
      end

      it "rejects an end before the start" do
        expect do
          post provider_closures_path, params: params.merge(ends_on: (today + 6).iso8601)
        end.not_to change(ProviderClosure, :count)

        follow_redirect!
        expect(inertia).to have_props(errors: { ends_on: [ error_message(:ends_on, :greater_than_or_equal_to) ] })
      end

      it "rejects dates that are not dates" do
        expect do
          post provider_closures_path, params: params.merge(starts_on: "mañana", ends_on: "")
        end.not_to change(ProviderClosure, :count)

        expect(response).to redirect_to(provider_operational_settings_path)
      end

      it "rejects a range that overlaps another closure of the provider" do
        create_closure(starts_on: today + 8, ends_on: today + 12)

        expect { post provider_closures_path, params: }.not_to change { provider.closures.count }

        follow_redirect!
        expect(inertia).to have_props(errors: { base: [ error_message(:base, :overlaps) ] })
      end
    end
  end

  describe "PATCH /provider/closures/:id" do
    let!(:closure) { create_closure }

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "updates the closure" do
        patch provider_closure_path(closure), params: { ends_on: (today + 10).iso8601, reason: "Feriado" }

        expect(response).to redirect_to(provider_operational_settings_path)
        expect(closure.reload).to have_attributes(starts_on: today + 7, ends_on: today + 10, reason: "Feriado")
      end

      it "keeps the closure when the change is invalid" do
        patch provider_closure_path(closure), params: { reason: "" }

        expect(closure.reload.reason).to eq("Vacaciones")
        follow_redirect!
        expect(inertia).to have_props(errors: { reason: [ error_message(:reason, :blank) ] })
      end

      it "does not overlap with itself but rejects overlapping another closure" do
        other = create_closure(starts_on: today + 20, ends_on: today + 22)

        patch provider_closure_path(closure), params: { ends_on: (today + 10).iso8601 }
        expect(closure.reload.ends_on).to eq(today + 10)

        patch provider_closure_path(other), params: { starts_on: (today + 10).iso8601 }
        expect(other.reload.starts_on).to eq(today + 20)
      end

      it "returns 404 for a closure of another provider and leaves it untouched" do
        foreign = create_closure(providers(:endulzate), starts_on: today + 30, ends_on: today + 31)

        patch provider_closure_path(foreign), params: { reason: "Mío ahora" }

        expect(response).to have_http_status(:not_found)
        expect(foreign.reload.reason).to eq("Vacaciones")
      end
    end

    it "redirects to sign in without a session" do
      patch provider_closure_path(closure), params: { reason: "Otro" }

      expect(response).to redirect_to(sign_in_path)
      expect(closure.reload.reason).to eq("Vacaciones")
    end
  end

  describe "DELETE /provider/closures/:id" do
    let!(:closure) { create_closure }

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "deletes the closure and says so" do
        expect { delete provider_closure_path(closure) }.to change { provider.closures.count }.by(-1)

        expect(response).to redirect_to(provider_operational_settings_path)
        expect(flash[:notice]).to eq(I18n.t("flash.provider_closure_deleted"))
      end

      it "returns 404 for a closure of another provider and keeps it" do
        foreign = create_closure(providers(:endulzate), starts_on: today + 30, ends_on: today + 31)

        expect { delete provider_closure_path(foreign) }.not_to change(ProviderClosure, :count)

        expect(response).to have_http_status(:not_found)
      end

      it "deletes a closure that is already in progress" do
        in_progress = create_closure(starts_on: today, ends_on: today + 2, reason: "Obra")

        expect { delete provider_closure_path(in_progress) }.to change { provider.closures.count }.by(-1)
      end
    end

    it "redirects a consumer to the home page and keeps the closure" do
      sign_in users(:one), role: :consumer

      expect { delete provider_closure_path(closure) }.not_to change(ProviderClosure, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end
