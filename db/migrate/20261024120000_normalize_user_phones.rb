# frozen_string_literal: true

class NormalizeUserPhones < ActiveRecord::Migration[8.1]
  class User < ActiveRecord::Base; end

  def up
    User.where.not(phone: nil).find_each do |user|
      phone = Phonelib.parse(user.phone)
      normalized = phone.e164 if phone.valid? && phone.types.intersect?(%i[mobile fixed_or_mobile])

      say "Se borra el teléfono inválido #{user.phone.inspect} (user #{user.id})" unless normalized
      user.update_columns(phone: normalized)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
