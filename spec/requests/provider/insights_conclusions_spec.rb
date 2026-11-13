# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider::Insights conclusions", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :reviews, :admins

  let(:client) { instance_double(AnthropicMessagesClient, create_summary: { ok: true, text: "Las puntuaciones son favorables." }) }
  let(:period) { { desde: Date.current.beginning_of_month.iso8601, hasta: Date.current.end_of_month.iso8601 } }

  def review(menu: menus(:milanesa), description: nil)
    Review.create!(menu:, rating: 5, description:, created_at: Date.current.in_time_zone)
  end

  before do
    allow(AnthropicMessagesClient).to receive(:new).and_return(client)
  end

  it "responde solo tras POST y nunca devuelve comentarios ni el payload" do
    sign_in users(:provider_user), role: :provider
    5.times { review(description: "La milanesa llegó tibia y tenía buen sabor") }

    get provider_insights_path
    expect(response).to have_http_status(:ok)
    expect(AnthropicMessagesClient).not_to have_received(:new)

    allow(client).to receive(:create_summary).and_return(ok: true, text: "La valoración general es favorable.")
    post provider_insights_conclusions_path, params: period

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "success" => true, "text" => "La valoración general es favorable.",
      "period" => { "from" => period[:desde], "to" => period[:hasta] },
      "review_count" => 5, "generated_by_ai" => true
    )
    expect(response.parsed_body).to include("generated_at", "generated_at_label")
    expect(response.body).not_to include("La milanesa llegó tibia", "comments", "authors", "ratings")
  end

  it "informa datos insuficientes sin consultar a Anthropic" do
    sign_in users(:provider_user), role: :provider
    4.times { review }
    expect(client).not_to receive(:create_summary)

    post provider_insights_conclusions_path, params: period

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("insufficient_data")
    expect(response.parsed_body.dig("error", "review_count")).to eq(4)
  end

  it "aísla proveedores según la sesión, sin aceptar IDs del cliente" do
    sign_in users(:provider_user), role: :provider
    5.times { review(menu: menus(:sorrentinos)) }
    expect(client).not_to receive(:create_summary)

    post provider_insights_conclusions_path, params: period
    expect(response.parsed_body.dig("error", "code")).to eq("insufficient_data")

    post provider_insights_conclusions_path, params: period.merge(provider_id: providers(:endulzate).id)
    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_request")
  end

  it "rechaza períodos ausentes, mal formados, invertidos o fuera de límites" do
    sign_in users(:provider_user), role: :provider
    expect(client).not_to receive(:create_summary)
    invalid = [ {}, { desde: "2026-13-01", hasta: "2026-13-02" },
                { desde: period[:hasta], hasta: period[:desde] },
                { desde: Date.current.next_month.iso8601, hasta: Date.current.next_month.iso8601 } ]

    invalid.each do |params|
      Rails.configuration.x.rate_limit_store.clear
      post provider_insights_conclusions_path, params: params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_period")
    end
  end

  it "limita a tres intentos por usuario proveedor en quince minutos" do
    sign_in users(:provider_user), role: :provider
    5.times { review }
    expect(client).to receive(:create_summary).exactly(3).times.and_return(ok: true, text: "La valoración es favorable.")

    3.times do
      post provider_insights_conclusions_path, params: period
      expect(response).to have_http_status(:ok)
    end
    post provider_insights_conclusions_path, params: period

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig("error", "code")).to eq("rate_limited")
  end

  it "mantiene el límite separado entre usuarios" do
    sign_in users(:provider_user), role: :provider
    5.times { review }
    3.times { post provider_insights_conclusions_path, params: period }

    sign_in users(:other_provider_user), role: :provider
    5.times { review(menu: menus(:sorrentinos)) }
    post provider_insights_conclusions_path, params: period

    expect(response).to have_http_status(:ok)
  end

  %w[configuration_missing timeout external_unavailable invalid_response rate_limited].each do |code|
    it "devuelve un error controlado para #{code}" do
      sign_in users(:provider_user), role: :provider
      5.times { review }
      allow(client).to receive(:create_summary).and_return(ok: false, error: { code: })

      post provider_insights_conclusions_path, params: period

      expect(response.parsed_body.dig("error", "code")).to eq(code)
      expect(response.body).not_to include("ANTHROPIC_API_KEY", "comments", "payload")
    end
  end

  it "impide el acceso sin sesión y a otros roles" do
    expect(client).not_to receive(:create_summary)
    post provider_insights_conclusions_path, params: period
    expect(response).to redirect_to(provider_sign_in_path)

    sign_in users(:one), role: :consumer
    post provider_insights_conclusions_path, params: period
    expect(response).to redirect_to(root_path)

    sign_in users(:admin), role: :admin
    post provider_insights_conclusions_path, params: period
    expect(response).to redirect_to(root_path)
  end
end
