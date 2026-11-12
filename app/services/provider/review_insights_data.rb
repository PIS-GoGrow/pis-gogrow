# frozen_string_literal: true

class Provider::ReviewInsightsData
  MIN_REVIEWS = 5
  MAX_COMMENTS = 30
  MAX_COMMENT_LENGTH = 200
  MAX_PAYLOAD_BYTES = 8192

  EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i
  PHONE = /(?<![[:alnum:]])(?:\+?598[\s.-]?)?(?:0?9\d[\s.-]?\d{3}[\s.-]?\d{3}|2\d{3}[\s.-]?\d{4})(?![[:alnum:]])/
  DOCUMENT = /(?<!\d)(?:\d\.\d{3}\.\d{3}-\d|\b(?:c[eé]dula|C\.?I\.?|DNI)\s*(?:n[.°º]?\s*)?[:#]?\s*[\d.-]{7,})/i
  ORDER_REFERENCE = /\b(?:pedido|orden)\s*(?:n[uú]mero|n[.°º]?|#)?\s*\d{3,}\b/i
  SENSITIVE = /\b(?:diagn[oó]stico|enfermedad|medicaci[oó]n|historia cl[ií]nica|mi direcci[oó]n|vivo en)\b|\b(?:me llamo|soy)\s+\p{Lu}\p{L}+(?:\s+\p{Lu}\p{L}+){1,2}\b/i

  def initialize(range)
    @range = range
  end

  def call
    raise ArgumentError, "Se requiere una sesión de proveedor" unless Current.session&.provider? && Current.user&.provider

    reviews = Review.joins(:menu).left_joins(:order)
                    .where(menus: { provider_id: Current.user.provider.id })
                    .where(created_at: @range.first.in_time_zone..@range.last.in_time_zone.end_of_day)
                    .where("reviews.rating BETWEEN 1 AND 5 OR NULLIF(TRIM(reviews.description), '') IS NOT NULL")

    count = reviews.count
    return { ok: false, error: "insufficient_data", review_count: count } if count < MIN_REVIEWS

    ratings = reviews.where(rating: 1..5).group(:rating).count
    author_counts = reviews.group("COALESCE(reviews.consumer_id, orders.consumer_id)").count
    unknown_count = author_counts.delete(nil) || 0

    candidates = reviews.where.not(description: nil)
                        .order(created_at: :desc, id: :desc)
                        .limit(MAX_COMMENTS)
                        .pluck(:description)
    comments = candidates.filter_map { sanitize_comment(it) }

    payload = {
        period: { from: @range.first.iso8601, to: @range.last.iso8601 },
        review_count: count,
        ratings: (1..5).to_h { [ it, ratings.fetch(it, 0) ] },
        average_rating: ratings.empty? ? nil : (ratings.sum { |rating, quantity| rating * quantity }.fdiv(ratings.values.sum)).round(1),
        authors: {
          known_count: author_counts.size,
          repeat_count: author_counts.count { |_, quantity| quantity > 1 },
          max_reviews: author_counts.values.max || 0,
          unknown_review_count: unknown_count
        },
        comments:,
        comments_selection: { method: "newest_candidates", limit: MAX_COMMENTS, examined_count: candidates.size, included_count: comments.size }
    }
    while JSON.generate(payload).bytesize > MAX_PAYLOAD_BYTES && comments.any?
      comments.pop
      payload[:comments_selection][:included_count] = comments.size
    end

    { ok: true, payload: }
  end

  private

  def sanitize_comment(description)
    return if description.blank? || description.length > MAX_COMMENT_LENGTH || description.match?(SENSITIVE)

    text = description.gsub(EMAIL, "[correo oculto]")
                      .gsub(DOCUMENT, "[documento oculto]")
                      .gsub(PHONE, "[teléfono oculto]")
                      .gsub(ORDER_REFERENCE, "[pedido oculto]")
    return unless text.gsub(/\[(?:correo|documento|teléfono|pedido) oculto\]/, "").match?(/\p{L}/)

    text
  end
end
