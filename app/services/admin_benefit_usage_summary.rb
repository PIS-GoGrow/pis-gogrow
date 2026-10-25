# frozen_string_literal: true

class AdminBenefitUsageSummary
  MAX_PAYLOAD_BYTES = 16_384
  SYSTEM_PROMPT = <<~PROMPT.freeze
    Actuás como analista del beneficio de alimentación contratado por la empresa. Escribí para RRHH un resumen breve, claro y profesional en español.
    Usá exclusivamente el JSON recibido. No inventes cifras, porcentajes ni fechas; null significa desconocido, nunca cero.
    Explicá el nivel de utilización, las viandas confirmadas, las viandas con subsidio mensual, la inversión económica agregada y la evolución de pedidos y viandas. Mencioná la participación solo si está disponible y las anomalías solo si están respaldadas por los datos.
    No compares la participación entre meses. Diferenciá pedidos y viandas confirmados de los pendientes, y el subsidio mensual de otros beneficios especiales.
    La inversión representa subsidio comprometido sin IVA, no dinero efectivamente pagado.
    No afirmes mejoras de satisfacción o retención laboral sin datos ni presentes correlaciones como causalidad demostrada.
    Reconocé los meses abiertos, los valores desconocidos y que los registros históricos conservados no son snapshots inmutables.
    Priorizá observaciones concretas. Si hacés recomendaciones, que sean prudentes y justificadas. No solicites información adicional ni completes estadísticas con contenido ficticio.
  PROMPT

  def initialize(payload:, client: AnthropicMessagesClient.new)
    @payload = payload
    @client = client
  end

  def call
    return failure("invalid_payload") unless @payload.is_a?(AdminBenefitUsageAiPayload)

    payload_json = JSON.generate(@payload.to_h)
    return failure("payload_too_large") if payload_json.bytesize > MAX_PAYLOAD_BYTES

    @client.create_summary(system: SYSTEM_PROMPT, payload_json:)
  rescue ArgumentError, KeyError, JSON::GeneratorError
    failure("invalid_payload")
  end

  private

  def failure(code)
    { ok: false, error: { code: } }
  end
end
