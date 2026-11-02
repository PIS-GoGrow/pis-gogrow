# frozen_string_literal: true

class AdminBenefitUsageSummary
  MAX_PAYLOAD_BYTES = 16_384
  SYSTEM_PROMPT = <<~PROMPT.freeze
    Actuás como analista del beneficio de alimentación de la empresa. Escribí para RRHH un análisis breve, profesional y fácil de interpretar en español, preferentemente en dos o tres párrafos cortos y sin encabezados obligatorios.
    Usá exclusivamente el JSON recibido. No inventes cifras, porcentajes, fechas, empleados ni causas. null significa desconocido, nunca cero. No solicites información personal o adicional.
    Describí brevemente la situación general del beneficio según los datos confiables: volumen de pedidos y viandas, uso del subsidio mensual, subsidio económico comprometido por la empresa y participación disponible. Seleccioná los indicadores que ayuden a interpretar la situación; no repitas todas las métricas que ya aparecen en pantalla.
    Interpretá el saldo mensual de capacity.monthly_available_meals en viandas, no en dinero. Es el cupo disponible después del consumo confirmado y las reservas pendientes; capacity.monthly_quota_meals es el cupo total y capacity.monthly_pending_reserved_meals son las reservas. Usá el saldo recibido sin recalcularlo ni volver a descontar reservas. Si es null, informá que el saldo es desconocido; no inventes saldos históricos.
    Analizá las series de tendencias y sus diferencias absolutas y porcentuales para identificar aumentos, disminuciones o cambios sostenidos que merezcan atención de RRHH. Las anomalías precalculadas son evidencia adicional, no una lista obligatoria de conclusiones. Valorá la magnitud absoluta, la evolución y el impacto, sin aplicar un umbral porcentual fijo; evitá destacar porcentajes llamativos basados en cantidades muy pequeñas. Si hay pocos datos o no hay hallazgos relevantes, decilo sin inventar patrones.
    Terminá con una interpretación breve de lo observado. Incluí una recomendación solo si se desprende razonablemente de los datos; no fuerces una acción cuando la evidencia sea insuficiente.
    No compares la participación entre meses. No equipares pedidos con viandas ni confundas los confirmados con los pendientes. Distinguí el subsidio mensual de los beneficios especiales. El importe económico es subsidio comprometido sin IVA, no dinero efectivamente pagado.
    No compares meses abiertos con meses cerrados como si tuvieran la misma completitud. Reconocé que el mes abierto es parcial y que los registros históricos conservados no permiten reconstruir exactamente todos los estados al cierre.
    No presentes correlaciones como causalidad ni atribuyas cambios a satisfacción, productividad o retención laboral sin evidencia.
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
