# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::OrderDeadlines", type: :request do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }
  let(:previous_deadline) { "10:00" }

  before { provider.update!(order_deadline: previous_deadline) }

  def deadline_of(provider)
    provider.reload.order_deadline&.strftime("%H:%M")
  end

  describe "PATCH /provider/order_deadline" do
    it "redirects to sign in without a session" do
      patch provider_order_deadline_path, params: { order_deadline: "18:30" }

      expect(response).to redirect_to(sign_in_path)
      expect(deadline_of(provider)).to eq(previous_deadline)
    end

    it "redirects a consumer to the home page without touching any deadline" do
      sign_in users(:one), role: :consumer

      patch provider_order_deadline_path, params: { order_deadline: "18:30" }

      expect(response).to redirect_to(root_path)
      expect(deadline_of(provider)).to eq(previous_deadline)
    end

    context "as a provider" do
      before { sign_in users(:provider_user), role: :provider }

      it "saves the new deadline and shows it back in the dashboard" do
        patch provider_order_deadline_path, params: { order_deadline: "18:30" }

        expect(response).to redirect_to(provider_dashboard_path)
        expect(deadline_of(provider)).to eq("18:30")
        follow_redirect!
        expect(inertia).to render_component("provider/dashboard/index")
        expect(inertia).to have_flash(notice: I18n.t("flash.order_deadline_updated"))
        expect(inertia).to have_props(provider: { order_deadline: "18:30" })
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

          expect(response).to redirect_to(provider_dashboard_path)
          expect(deadline_of(provider)).to be_nil
          follow_redirect!
          expect(inertia).to have_props(provider: { order_deadline: nil })
        end
      end

      %w[24:00 23:60 9:30 12:5 18:30:00 abc -01:00].each do |invalid|
        it "rejects #{invalid.inspect} and keeps the previous deadline" do
          patch provider_order_deadline_path, params: { order_deadline: invalid }

          expect(response).to redirect_to(provider_dashboard_path)
          expect(deadline_of(provider)).to eq(previous_deadline)
          follow_redirect!
          expect(inertia).to have_props(errors: { order_deadline: [ I18n.t("validations.invalid_order_deadline") ] })
        end
      end
    end
  end
end
