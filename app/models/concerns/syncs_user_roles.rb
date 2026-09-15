# frozen_string_literal: true

# Usado para mantener actualizada la columna roles de User.
# Cada vez que un provider/consumer/admin cambia, se borra o se crea,
# se va a el usuario correspondiente y se actualiza la columna roles para
# reflejar el cambio (por ejemplo, si un provider se borra, su usuario
# debería dejar de tener el rol provider)
module SyncsUserRoles
  extend ActiveSupport::Concern

  included do
    belongs_to :user

    after_create_commit -> { User.find_by(id: user_id)&.sync_roles! }
    after_destroy_commit -> { User.find_by(id: user_id)&.sync_roles! }
    after_update_commit :sync_roles_on_user_change
  end

  private

  def sync_roles_on_user_change
    return unless saved_change_to_user_id?

    previous_user_id, new_id = saved_change_to_user_id
    User.find_by(id: previous_user_id)&.sync_roles!
    User.find_by(id: new_id)&.sync_roles!
  end
end
