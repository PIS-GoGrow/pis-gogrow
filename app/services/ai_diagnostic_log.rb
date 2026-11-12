# frozen_string_literal: true

class AiDiagnosticLog
  def self.write(level, event:, **fields)
    Rails.logger.public_send(level, JSON.generate({ event:, request_id: token(Current.request_id), **fields }.compact))
  end

  def self.token(value)
    value if value.is_a?(String) && value.match?(/\A[a-zA-Z0-9._:-]{1,100}\z/)
  end
end
