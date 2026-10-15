# frozen_string_literal: true

namespace :notifications do
  desc "Sincroniza Notification::Configuration con config/notifications.yml"
  task sync: :environment do
    Notification::Configuration.sync!
  end

  desc "Crea o cierra las alertas de deuda según la deuda actual de cada empleado"
  task check_debt_alerts: :environment do
    Company.find_each(&:check_debt_alerts!)
  end
end
