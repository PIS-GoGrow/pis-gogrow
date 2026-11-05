# frozen_string_literal: true

require Rails.root.join("lib/ibp041/local_snapshot_qa")

namespace :ibp041 do
  namespace :qa do
    task :inspect, [ :company_id ] => :environment do |_task, args|
      puts JSON.pretty_generate(Ibp041::LocalSnapshotQa.new(company_id: args.fetch(:company_id)).inspect_destination)
    end

    task :load, [ :company_id ] => :environment do |_task, args|
      puts JSON.pretty_generate(Ibp041::LocalSnapshotQa.new(company_id: args.fetch(:company_id)).load!)
    end

    task :list, [ :company_id ] => :environment do |_task, args|
      puts JSON.pretty_generate(Ibp041::LocalSnapshotQa.new(company_id: args.fetch(:company_id)).list)
    end

    task :remove, [ :company_id ] => :environment do |_task, args|
      puts "Fotografías ficticias eliminadas: #{Ibp041::LocalSnapshotQa.new(company_id: args.fetch(:company_id)).remove!}"
    end
  end
end
