# frozen_string_literal: true

require Rails.root.join("lib/ibp041/local_database_guard")
require Rails.root.join("lib/ibp041/fictional_snapshot_scenarios")

module Ibp041
  class LocalSnapshotQa
    def initialize(company_id:)
      @company_id = Integer(company_id.to_s, 10)
    end

    def inspect_destination
      {
        environment: Rails.env,
        database: connection.select_value("SELECT current_database()"),
        configured_host: ENV["PGHOST"],
        server_address: connection.select_value("SELECT host(inet_server_addr())"),
        server_port: connection.select_value("SELECT inet_server_port()"),
        company_id: @company_id,
        employees: Company.find(@company_id).consumers.count,
        authorized: local_database?
      }
    end

    def list
      verify_local_database!
      snapshots.map do |snapshot|
        {
          month: snapshot.month.strftime("%Y-%m"), fictional: snapshot.fictional?,
          status: snapshot.status, captured_at: snapshot.captured_at.iso8601,
          employees: snapshot.employees, eligible_employees: snapshot.eligible_employees,
          confirmed_meals: snapshot.confirmed_meals, monthly_quota_meals: snapshot.monthly_quota_meals,
          monthly_unused_closed_meals: snapshot.monthly_unused_closed_meals
        }
      end
    end

    def load!
      verify_local_database!
      Company.find(@company_id)
      BenefitUsageMonthlySnapshot.transaction do
        existing = snapshots.index_by { it.month.strftime("%Y-%m") }
        raise "Existe una fotografía real; no se modificó ningún período" if existing.values.any? { !it.fictional? }
        unless existing.all? { |key, snapshot| scenario_snapshot?(snapshot, key) }
          raise "Existe una fotografía ficticia diferente; no se modificó ningún período"
        end

        FictionalSnapshotScenarios.months.each do |key|
          month = Date.iso8601("#{key}-01")
          next if existing.key?(key)

          BenefitUsageMonthlySnapshot.create!(company_id: @company_id, month:, fictional: true,
                                              **FictionalSnapshotScenarios.attributes(key))
        end
      end
      list
    end

    def remove!
      verify_local_database!
      ids = snapshots.filter_map do |snapshot|
        key = snapshot.month.strftime("%Y-%m")
        snapshot.id if scenario_snapshot?(snapshot, key)
      end
      BenefitUsageMonthlySnapshot.where(id: ids).delete_all
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def snapshots
      BenefitUsageMonthlySnapshot.where(company_id: @company_id,
                                        month: FictionalSnapshotScenarios.months.map { Date.iso8601("#{it}-01") })
                                 .order(:month)
    end

    def scenario_snapshot?(snapshot, key)
      expected = FictionalSnapshotScenarios.attributes(key)
      snapshot.fictional? && expected.all? do |field, value|
        actual = snapshot.public_send(field)
        value = value.to_s if field == :status
        value = value.to_d if field == :company_subsidy_amount
        actual == value
      end
    end

    def local_database?
      LocalDatabaseGuard.allowed?
    end

    def verify_local_database!
      raise "La conexión no es la base local de desarrollo autorizada" unless local_database?
    end
  end
end
