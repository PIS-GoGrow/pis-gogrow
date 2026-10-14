# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::OperationalSettings", type: :request do
  fixtures :users, :providers

  describe "GET /provider/operational_settings" do
    it "redirects visitors without a session to the sign in page" do
      get provider_operational_settings_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_operational_settings_path

      expect(response).to redirect_to(root_path)
    end

    it "shows only the signed-in provider's deadline" do
      providers(:tuviandita).update!(order_deadline: Time.zone.parse("18:30"))
      providers(:endulzate).update!(order_deadline: Time.zone.parse("11:00"))
      sign_in users(:provider_user), role: :provider

      get provider_operational_settings_path

      expect(inertia).to render_component("provider/operational_settings/show")
      expect(inertia).to have_props(provider: { order_deadline: "18:30" })
    end

    it "sends a null deadline when none is configured" do
      providers(:tuviandita).update!(order_deadline: nil)
      sign_in users(:provider_user), role: :provider

      get provider_operational_settings_path

      expect(inertia).to have_props(provider: { order_deadline: nil })
    end

    describe "scheduled closures" do
      let(:today) { Date.new(2026, 10, 12) }

      before do
        travel_to Time.zone.local(2026, 10, 12, 9, 0)
        sign_in users(:provider_user), role: :provider
      end

      def close(owner, from, to, reason)
        owner.closures.create!(starts_on: from, ends_on: to, reason:)
      end

      it "sends today's date as the server sees it" do
        get provider_operational_settings_path

        expect(inertia).to have_props(today: "2026-10-12")
      end

      it "sends an empty list when there are none" do
        get provider_operational_settings_path

        expect(inertia).to have_props(closures: [])
      end

      it "sends only the signed-in provider's closures, soonest first, with the period written out" do
        close(providers(:tuviandita), today + 40, today + 41, "Obra")
        close(providers(:tuviandita), today + 7, today + 9, "Vacaciones")
        close(providers(:endulzate), today + 7, today + 9, "De otro")

        get provider_operational_settings_path

        expect(inertia.props[:closures]).to match([
          a_hash_including(reason: "Vacaciones", starts_on: "2026-10-19", ends_on: "2026-10-21", period: "19 al 21 de octubre de 2026"),
          a_hash_including(reason: "Obra", starts_on: "2026-11-21", ends_on: "2026-11-22", period: "21 al 22 de noviembre de 2026")
        ])
      end

      it "leaves out the closures that already ended" do
        ended = close(providers(:tuviandita), today, today + 1, "Pasado")
        close(providers(:tuviandita), today + 7, today + 9, "Vacaciones")
        travel_to Time.zone.local(2026, 10, 14, 9, 0)

        get provider_operational_settings_path

        expect(inertia.props[:closures].pluck(:id)).not_to include(ended.id)
        expect(inertia.props[:closures].pluck(:reason)).to eq([ "Vacaciones" ])
      end

      it "keeps a closure that ends today" do
        close(providers(:tuviandita), today, today + 1, "Obra")
        travel_to Time.zone.local(2026, 10, 13, 9, 0)

        get provider_operational_settings_path

        expect(inertia.props[:closures].pluck(:reason)).to eq([ "Obra" ])
      end

      {
        "a single day" => [ Date.new(2027, 6, 9), Date.new(2027, 6, 9), "9 de junio de 2027" ],
        "a range within a month" => [ Date.new(2027, 6, 9), Date.new(2027, 6, 27), "9 al 27 de junio de 2027" ],
        "a range across months" => [ Date.new(2027, 6, 28), Date.new(2027, 7, 3), "28 de junio al 3 de julio de 2027" ],
        "a range across years" => [ Date.new(2026, 12, 28), Date.new(2027, 1, 3), "28 de diciembre de 2026 al 3 de enero de 2027" ]
      }.each do |description, (from, to, period)|
        it "writes #{description} as #{period.inspect}" do
          close(providers(:tuviandita), from, to, "Cierre")

          get provider_operational_settings_path

          expect(inertia.props[:closures].first).to include(period:)
        end
      end
    end
  end
end
