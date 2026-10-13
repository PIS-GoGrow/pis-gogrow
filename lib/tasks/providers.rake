# frozen_string_literal: true

namespace :providers do
  desc "Invita a un proveedor: bin/rails 'providers:invite[Nombre,correo@ejemplo.com,COMPANY_ID]'"
  task :invite, [ :name, :email, :company_id ] => :environment do |_, args|
    Providers::Invite.call(name: args.name, email: args.email, company: Company.find(args.company_id))
    puts "Invitación enviada a #{args.email}"
  end
end
