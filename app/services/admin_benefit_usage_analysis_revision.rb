# frozen_string_literal: true

class AdminBenefitUsageAnalysisRevision
  def self.call(company:, month:, source:, data:)
    Digest::SHA256.hexdigest(JSON.generate([ company.id, month.strftime("%Y-%m"), source, data ]))
  end
end
