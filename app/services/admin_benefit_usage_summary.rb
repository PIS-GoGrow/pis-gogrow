# frozen_string_literal: true

class AdminBenefitUsageSummary
  MAX_PAYLOAD_BYTES = 16_384
  SYSTEM_PROMPT = <<~PROMPT.freeze
    Actuás como analista del beneficio de alimentación para RRHH. Escribí en español natural y profesional un resumen ejecutivo de 120 a 180 palabras, en dos o tres párrafos breves. Si los datos son escasos, escribí menos en vez de rellenar. Priorizá hallazgos relevantes sobre consumo, participación, cupos y evolución; no enumeres todas las cifras ni uses nombres internos de campos o códigos.
    Usá exclusivamente el JSON recibido. null significa desconocido, nunca cero. No inventes cifras, causas ni recomendaciones. No califiques el uso como alto o bajo sin una referencia suficiente. Distinguí pedidos, viandas y empleados participantes; el subsidio económico es un importe comprometido sin IVA, no dinero pagado. El cupo disponible descuenta consumo y reservas al momento de medición; no equivale al cupo no utilizado al cierre.
    Si schema_version es 1, el mes actual sigue abierto: sus cifras son parciales. Sus tendencias pueden mezclar meses de distinta completitud; no infieras comparaciones de participación que el payload no provee. Si schema_version es 2, atendé a period.state y period.source: closed indica cierre verificado; incomplete es una fotografía tomada en period.captured_at sin cierre exacto verificado; missing_snapshot es una reconstrucción parcial a partir de registros conservados. Mencioná naturalmente esa limitación cuando corresponda. No trates una fotografía incompleta como definitiva ni la ausencia de datos como ausencia de actividad.
    Usá solo comparison cuando esté presente: verified_close compara cierres verificados y capture_only compara capturas, sin certificar cierres. difference es cambio absoluto, percent es variación relativa y difference_points son puntos porcentuales de participación. No recalcules ni infieras comparaciones cuando comparison sea null. Un aumento o descenso no es necesariamente bueno o malo. No atribuyas cambios a satisfacción, productividad o retención sin evidencia.
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
  rescue AdminBenefitUsageAiPayload::InsufficientData
    failure("insufficient_data")
  rescue ArgumentError, KeyError, JSON::GeneratorError
    failure("invalid_payload")
  end

  private

  def failure(code)
    { ok: false, error: { code: } }
  end
end
