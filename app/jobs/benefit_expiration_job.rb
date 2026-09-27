# frozen_string_literal: true

# Job para expirar beneficios pasados. Cuando termina, llama a BenefitAssignation
class BenefitExpirationJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Benefit.current
           .where(due_date: ...date)
           .update_all(status: :expired, updated_at: Time.current)

    BenefitAssignationJob.perform_later
  end
end
