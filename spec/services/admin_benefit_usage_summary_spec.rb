# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminBenefitUsageSummary do
  let(:stats) do
    change = { reference: nil, difference: nil, percent: nil }
    {
      period: { month: Date.new(2032, 4, 1) },
      orders: { confirmed_orders: 2, confirmed_meals: 3, pending_orders: 1, pending_meals: 1 },
      benefits: {
        monthly_subsidized_meals: 2, confirmed_meals_without_monthly_subsidy: 1,
        company_subsidy_amount: BigDecimal("1500.25"), monthly_pending_reserved_meals: 1,
        monthly_quota_meals: nil
      },
      employees: { participation_percent: nil, eligibility: { eligible: 0 }, eligible_without_orders: nil },
      trends: { months: [
        { month: Date.new(2032, 4, 1), complete: false, confirmed_orders: 2, confirmed_meals: 3,
          monthly_subsidized_meals: 2, company_subsidy_amount: BigDecimal("1500.25"),
          changes: { confirmed_orders: change, confirmed_meals: change,
                     monthly_subsidized_meals: change, company_subsidy_amount: change } }
      ] },
      anomalies: [], warnings: [ { code: "open_month_partial", scope: "trends" } ]
    }
  end
  let(:payload) { AdminBenefitUsageAiPayload.new(stats:) }
  let(:client) { instance_double(AnthropicMessagesClient) }
  let(:summary) { described_class.new(payload:, client:) }

  it "passes only the approved JSON and instructions to the client" do
    stats[:employee] = { name: "Nombre privado", email: "privado@example.com" }
    stats[:orders][:individual_orders] = [ { address: "Dirección privada" } ]
    arguments = nil
    allow(client).to receive(:create_summary) do |**received|
      arguments = received
      { ok: true, text: "Uso estable del beneficio." }
    end

    expect(summary.call).to eq(ok: true, text: "Uso estable del beneficio.")
    expect(client).to have_received(:create_summary).once
    json = JSON.parse(arguments.fetch(:payload_json))
    expect(json.keys).to contain_exactly("schema_version", "period", "consumption", "participation",
                                        "trends", "anomalies", "warnings")
    expect(json.dig("consumption", "company_subsidy_amount")).to eq("1500.25")
    expect(arguments.fetch(:payload_json)).not_to include("Nombre privado", "privado@example.com", "Dirección privada")
    expect(arguments.fetch(:system)).to include("null significa desconocido", "sin IVA", "No compares la participación")
    expect(arguments.keys).to contain_exactly(:system, :payload_json)
  end

  it "asks for evidence-backed findings without repeating every metric" do
    prompt = described_class::SYSTEM_PROMPT

    expect(prompt).to include("series de tendencias", "diferencias absolutas y porcentuales", "anomalías precalculadas")
    expect(prompt).to include("no repitas todas las métricas", "sin aplicar un umbral porcentual fijo")
    expect(prompt).to include("null significa desconocido", "No solicites información personal", "No compares la participación")
    expect(prompt).to include("mes abierto es parcial", "sin IVA", "no dinero efectivamente pagado")
  end

  it "returns a controlled error for oversized payloads without sending them" do
    allow(payload).to receive(:to_h).and_return(data: "x" * described_class::MAX_PAYLOAD_BYTES)
    expect(client).not_to receive(:create_summary)

    expect(summary.call).to eq(ok: false, error: { code: "payload_too_large" })
  end

  it "rejects a raw hash instead of sending unreviewed fields" do
    expect(client).not_to receive(:create_summary)
    result = described_class.new(payload: { secret: "private" }, client:).call

    expect(result).to eq(ok: false, error: { code: "invalid_payload" })
  end

  it "preserves the original statistics if the external service fails" do
    original = stats.deep_dup
    allow(client).to receive(:create_summary).and_return(ok: false, error: { code: "external_unavailable" })

    expect(summary.call).to eq(ok: false, error: { code: "external_unavailable" })
    expect(stats).to eq(original)
  end
end
