# frozen_string_literal: true

# Job para expirar beneficios pasados y asignar como actuales los que eran futuros.
# Cuando termina, llama a BenefitAssignation.
class BenefitUpdateJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Benefit.expire_old! date
    Benefit.make_current! date

    BenefitAssignationJob.perform_later
  end
end
