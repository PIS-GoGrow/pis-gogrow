# frozen_string_literal: true

namespace :providers do
  desc "Invita a un proveedor: bin/rails 'providers:invite[Nombre,correo@ejemplo.com,COMPANY_ID]'"
  task :invite, [ :name, :email, :company_id ] => :environment do |_, args|
    company = args.company_id.present? ? Company.find(args.company_id) : Company.first
    raise "No se encontró ninguna empresa en la base de datos" unless company

    Providers::Invite.call(name: args.name, email: args.email, company: company)
    puts "Invitación enviada a #{args.email} (empresa: #{company.name})"
  end
end
