# frozen_string_literal: true

class AnthropicMessagesClient
  def initialize(connection: nil, env: ENV)
    @connection = connection
    @env = env
  end

  def create_summary(system:, payload_json:)
    api_key = @env["ANTHROPIC_API_KEY"]
    model = @env["ANTHROPIC_MODEL"]
    return failure("configuration_missing") if api_key.blank? || model.blank?

    response = connection.post("/v1/messages") do |request|
      request.headers["Authorization"] = "Bearer #{api_key}"
      request.headers["anthropic-version"] = "2026-10-21"
      request.headers["Content-Type"] = "application/json"
      request.body = JSON.generate(
        model:, max_tokens: 500, system:,
        messages: [ { role: "user", content: payload_json } ]
      )
    end

    return http_failure(response) unless response.success?
    return failure("invalid_response") unless response.body.is_a?(String)

    message = JSON.parse(response.body)
    details = message["stop_details"] if message.is_a?(Hash)
    return failure("refused") if details.is_a?(Hash) && details["type"] == "refusal"
    return failure("invalid_response") unless message.is_a?(Hash) && message["type"] == "message" &&
                                              message["role"] == "assistant" && message["stop_reason"] == "end_turn"

    blocks = message["content"]
    return failure("invalid_response") unless blocks.is_a?(Array) && blocks.any? &&
                                              blocks.all? { it.is_a?(Hash) && it["type"] == "text" && it["text"].is_a?(String) }

    summary = blocks.pluck("text").join("\n").strip
    summary.present? ? { ok: true, text: summary } : failure("invalid_response")
  rescue Faraday::TimeoutError
    failure("timeout")
  rescue Faraday::ConnectionFailed, Faraday::Error
    failure("external_unavailable")
  rescue JSON::ParserError
    failure("invalid_response")
  end

  private

  def connection
    @connection ||= Faraday.new(url: "https://api.anthropic.com") do |client|
      client.options.open_timeout = 5
      client.options.timeout = 20
      client.adapter Faraday.default_adapter
    end
  end

  def http_failure(response)
    return failure("spend_limit_reached") if spend_limit_response?(response)

    code = case response.status
    when 401 then "authentication_failed"
    when 402, 403 then "permission_or_billing"
    when 429 then "rate_limited"
    when 408, 504 then "timeout"
    when 500..599 then "external_unavailable"
    else "invalid_response"
    end
    failure(code)
  end

  def spend_limit_response?(response)
    return false unless [ 400, 429 ].include?(response.status) && response.body.is_a?(String)

    body = JSON.parse(response.body)
    return false unless body.is_a?(Hash) && body["error"].is_a?(Hash)

    error = body["error"]
    details = error["details"]
    return true if details.is_a?(Hash) && details["error_code"] == "enforced_spend_limit_reached"

    response.status == 400 && error["type"] == "invalid_request_error" &&
      error["message"].is_a?(String) &&
      error["message"].start_with?("You have reached your specified API usage limits",
                                   "You have reached your specified workspace API usage limits")
  rescue JSON::ParserError
    false
  end

  def failure(code)
    { ok: false, error: { code: } }
  end
end
