# frozen_string_literal: true

# Job para expirar beneficios pasados. Cuando termina, llama a BenefitAssignation.
class BenefitExpirationJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Benefit.expire_old! date

    BenefitAssignationJob.perform_later
  end
end
