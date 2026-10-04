# frozen_string_literal: true

namespace :accounts do
  desc "Crea las cuentas de empresa que les faltan a los pedidos ya existentes"
  task backfill_company: :environment do
    Order.includes(:accounts, consumer: :company, schedule: { menu: :provider }).find_each(&:ensure_accounts!)
  end
end
