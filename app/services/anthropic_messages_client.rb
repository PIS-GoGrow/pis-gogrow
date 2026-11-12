# frozen_string_literal: true

class AnthropicMessagesClient
  def initialize(connection: nil, env: ENV)
    @connection = connection
    @env = env
  end

  def create_summary(system:, payload_json:)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    api_key = @env["ANTHROPIC_API_KEY"]
    model = @env["ANTHROPIC_MODEL"]
    if api_key.blank? || model.blank?
      log_failure("configuration_missing", stage: "configuration", started_at:)
      return failure("configuration_missing")
    end

    AiDiagnosticLog.write(:info, event: "anthropic.request_started", model: AiDiagnosticLog.token(model), max_tokens: 2500)

    response = connection.post("/v1/messages") do |request|
      request.headers["Authorization"] = "Bearer #{api_key}"
      request.headers["x-api-key"] = api_key
      request.headers["anthropic-version"] = "2026-10-21"
      request.headers["Content-Type"] = "application/json"
      request.body = JSON.generate(
        model:, max_tokens: 2500, system:,
        messages: [ { role: "user", content: payload_json } ]
      )
    end

    unless response.success?
      log_failure("http_error", stage: "http", started_at:, response:, error_type: response_error_type(response))
      return http_failure(response)
    end
    unless response.body.is_a?(String)
      log_completion(response, started_at:, reason: "invalid_http_body")
      return failure("invalid_response")
    end

    message = JSON.parse(response.body)
    details = message["stop_details"] if message.is_a?(Hash)
    if (message.is_a?(Hash) && message["stop_reason"] == "refusal") ||
       (details.is_a?(Hash) && details["type"] == "refusal")
      log_completion(response, started_at:, message:, reason: "generation_refused")
      return failure("refused")
    end
    unless message.is_a?(Hash) && message["type"] == "message" && message["role"] == "assistant" &&
           message["stop_reason"] == "end_turn"
      reason = message.is_a?(Hash) && message["stop_reason"] == "max_tokens" ? "max_tokens_exhausted" : "unexpected_response"
      log_completion(response, started_at:, message:, reason:)
      return failure("invalid_response")
    end

    blocks = message["content"]
    unless blocks.is_a?(Array) && blocks.any? && blocks.all? { valid_content_block?(it) }
      log_completion(response, started_at:, message:, reason: "unexpected_response")
      return failure("invalid_response")
    end

    summary = blocks.filter_map { it["text"] if it["type"] == "text" }.join("\n").strip
    log_completion(response, started_at:, message:, reason: ("empty_response" if summary.blank?))
    summary.present? ? { ok: true, text: summary } : failure("invalid_response")
  rescue Faraday::TimeoutError
    log_failure("timeout", stage: "transport", started_at:)
    failure("timeout")
  rescue Faraday::ConnectionFailed
    log_failure("connection_failed", stage: "transport", started_at:)
    failure("external_unavailable")
  rescue Faraday::Error
    log_failure("transport_error", stage: "transport", started_at:)
    failure("external_unavailable")
  rescue JSON::ParserError
    log_completion(response, started_at:, reason: "malformed_json")
    failure("invalid_response")
  end

  private

  def log_completion(response, started_at:, message: nil, reason: nil)
    blocks = message.is_a?(Hash) && message["content"].is_a?(Array) ? message["content"] : []
    text_blocks = blocks.filter_map { it["text"] if it.is_a?(Hash) && it["type"] == "text" && it["text"].is_a?(String) }
    text = text_blocks.join("\n").strip
    usage = message["usage"] if message.is_a?(Hash)
    AiDiagnosticLog.write(reason ? :warn : :info, event: "anthropic.request_completed",
                          stage: ("response_validation" if reason),
                          http_status: response.status, anthropic_request_id: AiDiagnosticLog.token(response.headers["request-id"]),
                          stop_reason: safe_stop_reason(message), block_types: blocks.map { safe_block_type(it) }.uniq,
                          text_blocks: text_blocks.length, usable_text: text.present?, output_characters: text.length,
                          input_tokens: safe_token_count(usage, "input_tokens"), output_tokens: safe_token_count(usage, "output_tokens"),
                          duration_ms: elapsed_ms(started_at), reason:)
  end

  def log_failure(reason, stage:, started_at:, response: nil, error_type: nil)
    AiDiagnosticLog.write(:warn, event: "anthropic.request_failed", stage:, reason:,
                          http_status: response&.status,
                          anthropic_request_id: AiDiagnosticLog.token(response&.headers&.[]("request-id")),
                          error_type:, duration_ms: elapsed_ms(started_at))
  end

  def response_error_type(response)
    return unless response.body.is_a?(String)

    body = JSON.parse(response.body)
    type = body["error"]["type"] if body.is_a?(Hash) && body["error"].is_a?(Hash)
    type if %w[invalid_request_error authentication_error permission_error rate_limit_error api_error overloaded_error not_found_error].include?(type)
  rescue JSON::ParserError
    nil
  end

  def safe_stop_reason(message)
    reason = message["stop_reason"] if message.is_a?(Hash)
    reason if %w[end_turn max_tokens stop_sequence tool_use pause_turn refusal model_context_window_exceeded].include?(reason)
  end

  def safe_block_type(block)
    type = block["type"] if block.is_a?(Hash)
    %w[text thinking redacted_thinking tool_use server_tool_use].include?(type) ? type : "unknown"
  end

  def safe_token_count(usage, key)
    value = usage[key] if usage.is_a?(Hash)
    value if value.is_a?(Integer) && value >= 0
  end

  def elapsed_ms(started_at)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
  end

  def valid_content_block?(block)
    return false unless block.is_a?(Hash)

    case block["type"]
    when "text" then block["text"].is_a?(String)
    when "thinking" then block["thinking"].is_a?(String) && block["signature"].is_a?(String)
    when "redacted_thinking" then block["data"].is_a?(String)
    else false
    end
  end

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
