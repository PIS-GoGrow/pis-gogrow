# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnthropicMessagesClient do
  let(:configuration) { { "ANTHROPIC_API_KEY" => "test-only-key", "ANTHROPIC_MODEL" => "configured-test-model" } }
  let(:response_status) { 200 }
  let(:response_body) do
    JSON.generate(type: "message", role: "assistant", stop_reason: "end_turn",
                  content: [ { type: "text", text: "Resumen claro." } ])
  end
  let(:requests) { [] }
  let(:connection) do
    Faraday.new(url: "https://api.anthropic.com") do |faraday|
      faraday.adapter :test do |stub|
        stub.post("/v1/messages") do |request|
          requests << { url: request.url.to_s, headers: request.request_headers.to_h, body: request.body.dup }
          [ response_status, { "Content-Type" => "application/json" }, response_body ]
        end
      end
    end
  end
  let(:client) { described_class.new(connection:, env: configuration) }
  let(:result) { client.create_summary(system: "Instrucciones de prueba", payload_json: '{"schema_version":1}') }

  it "sends one bounded Messages request with backend credentials and returns completed text" do
    expect(result).to eq(ok: true, text: "Resumen claro.")
    expect(requests.size).to eq(1)
    expect(requests.first[:url]).to eq("https://api.anthropic.com/v1/messages")
    expect(requests.first[:headers]).to include("Authorization" => "Bearer test-only-key",
                                                "anthropic-version" => "2026-10-21",
                                                "Content-Type" => "application/json")
    expect(JSON.parse(requests.first[:body])).to eq(
      "model" => "configured-test-model", "max_tokens" => 500, "system" => "Instrucciones de prueba",
      "messages" => [ { "role" => "user", "content" => '{"schema_version":1}' } ]
    )
  end

  it "does not send a request when either configuration value is missing" do
    configuration["ANTHROPIC_API_KEY"] = ""
    expect(result).to eq(ok: false, error: { code: "configuration_missing" })
    expect(requests).to be_empty

    configuration["ANTHROPIC_API_KEY"] = "test-only-key"
    configuration["ANTHROPIC_MODEL"] = nil
    expect(client.create_summary(system: "Instrucciones de prueba", payload_json: "{}")).to eq(
      ok: false, error: { code: "configuration_missing" }
    )
    expect(requests).to be_empty
  end

  it "rejects empty, malformed and truncated successful responses" do
    [ nil, "", "not json", JSON.generate(type: "message", role: "assistant", stop_reason: "max_tokens",
                                       content: [ { type: "text", text: "Parcial" } ]) ].each do |body|
      allow(client).to receive(:connection).and_return(Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") { [ 200, {}, body ] }
        end
      end)
      expect(client.create_summary(system: "Instrucciones de prueba", payload_json: "{}")).to eq(
        ok: false, error: { code: "invalid_response" }
      )
    end
  end

  it "rejects non-text content and blank text" do
    [ [ { type: "tool_use", id: "tool" } ], [ { type: "text", text: "  " } ] ].each do |blocks|
      allow(client).to receive(:connection).and_return(Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") do
            [ 200, {}, JSON.generate(type: "message", role: "assistant", stop_reason: "end_turn", content: blocks) ]
          end
        end
      end)
      expect(client.create_summary(system: "Instrucciones de prueba", payload_json: "{}")).to eq(
        ok: false, error: { code: "invalid_response" }
      )
    end
  end

  it "rejects a refusal detail even when the stop reason says end_turn" do
    refusal = JSON.generate(type: "message", role: "assistant", stop_reason: "end_turn",
                            stop_details: { type: "refusal", category: "other" },
                            content: [ { type: "text", text: "No puedo ayudar." } ])
    allow(client).to receive(:connection).and_return(Faraday.new(url: "https://api.anthropic.com") do |faraday|
      faraday.adapter :test do |stub|
        stub.post("/v1/messages") { [ 200, {}, refusal ] }
      end
    end)

    expect(client.create_summary(system: "Instrucciones", payload_json: "{}")).to eq(
      ok: false, error: { code: "refused" }
    )
  end

  it "recognizes documented spend limits without returning the provider's message" do
    [
      [ 400, { type: "invalid_request_error", message: "You have reached your specified API usage limits" } ],
      [ 429, { type: "rate_limit_error", details: { error_code: "enforced_spend_limit_reached" } } ]
    ].each do |status, error|
      allow(client).to receive(:connection).and_return(Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") { [ status, {}, JSON.generate(type: "error", error:) ] }
        end
      end)
      expect(client.create_summary(system: "Instrucciones", payload_json: "{}")).to eq(
        ok: false, error: { code: "spend_limit_reached" }
      )
    end
  end

  it "classifies authentication, billing, rate limit and external failures without exposing response bodies" do
    { 401 => "authentication_failed", 402 => "permission_or_billing", 403 => "permission_or_billing",
      429 => "rate_limited", 500 => "external_unavailable", 504 => "timeout",
      529 => "external_unavailable" }.each do |status, code|
      allow(client).to receive(:connection).and_return(Faraday.new(url: "https://api.anthropic.com") do |faraday|
        faraday.adapter :test do |stub|
          stub.post("/v1/messages") { [ status, {}, "secret diagnostic body" ] }
        end
      end)
      expect(client.create_summary(system: "Instrucciones de prueba", payload_json: "{}")).to eq(
        ok: false, error: { code: }
      )
    end
  end

  it "reports a timeout without retrying or exposing the API key" do
    attempts = 0
    timed_out_connection = Faraday.new(url: "https://api.anthropic.com") do |faraday|
      faraday.adapter :test do |stub|
        stub.post("/v1/messages") do
          attempts += 1
          raise Faraday::TimeoutError, "secret diagnostic body"
        end
      end
    end
    client = described_class.new(connection: timed_out_connection, env: configuration)

    expect(client.create_summary(system: "Instrucciones", payload_json: "{}")).to eq(
      ok: false, error: { code: "timeout" }
    )
    expect(attempts).to eq(1)
  end
end
