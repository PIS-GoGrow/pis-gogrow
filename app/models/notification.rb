# frozen_string_literal: true

# Representa una notificación que se le va a enviar al usuario.
# Una notificación puede estar activa o cerrada y puede requerir o no acción.
#
# Si el usuario tiene varios roles, la notificación solo le aparecerá cuando se loguee
# con el rol definido en la columna role de notificación.
#
# Checklist para agregar notificaciones a un flujo:
#
# 1. Revisar que exista la configuración: Todas las notificaciones deben tener un
#    Notification::Configuration asociado, por lo que es necesario que ya exista
#    la configuración que vamos a asociar a este flujo. Revisar el archivo
#      app/models/notification/configuration.rb
#    para ver más. Luego de esto, deberíamos obtener una clave de configuración.
# 2. Registrar el evento: Los tipos de notificaciones están separados según el
#    flujo o "evento" que los genera. En config/notifications.yml hay que agregar
#    en events la información de nuestro flujo:
#    2.1. Agregar bajo events una clave única para nuestro flujo. Por ejemplo, para
#         el flujo «Notificar confirmación de pedidos» podría ser order_confirmation.
#    2.2. Agregar la clave de configuración encontrada en el paso 1 bajo la clave del
#         paso 2.1.
#    2.3. Elegir el rol (consumer, admin, provider) para el cual este tipo de
#         notificación aplica.
#    2.4. Definir si la notificación requiere acción. Si requiere acción, el usuario
#         no la puede cerrar, sino que necesita hacer algo para que se cierre. En el
#         Figma, estas notificaciones aparecen en rojo.
#    Los detalles del formato están en config/notifications.yml.
# 3. Crear los locales: Es necesario agregar título y descripción de la notificación a
#    config/locales/es.yml. Si creamos una clave de evento 'event_key' en el paso 2,
#    tenemos que agregar al archivo:
#
#      notifications:
#        event_key:
#          title: "..."
#          description: "..."
#
#    si la notificación requiere datos extra del momento, los agregamos con %{dato}
#    adentro del string.
# 4. Crearla en el flujo: En el punto del flujo que sea necesario notificar a un
#    usuario, se crea una notificación llamando al servicio Notifier. Nunca habría
#    que llamar a Notification.create directamente.
#    Hay más información en app/services/notifier.rb de cómo crearlas.
# 5. Definir cómo cerrarlas: Si la notificación no requiere acción, este paso no es
#    necesario. Hay que definir en qué punto una notificación puede ser cerrada.
#    Cuando la condición se cumpla para que al usuario ya no le aparezca la
#    notificación, hay que llamar a Notification.close_by! o Notification.close_by.
#    Es necesario indicar la clave de evento, el objeto notifiable y el usuario
#    que se eligieron en el paso 3.
#    Las notificaciones que requieren acción no se van nunca si no hacemos esto, por
#    lo que hay que estar seguro de que eventualmente se va a llamar a close_by de
#    alguna forma, y que no hay manera de evitarlo si es que se realiza la acción
#    requerida.
class Notification < ApplicationRecord
  EVENT_KEYS = %i[
    order_confirmation
  ].to_set.freeze

  belongs_to :user
  belongs_to :notification_configuration, class_name: "Notification::Configuration"
  belongs_to :notifiable, polymorphic: true

  validates :title, presence: true
  validates :description, presence: true
  validate :role_belongs_to_user
  validate :event_exists

  scope :closed, -> { where.not closed_at: nil }
  scope :active, -> { where closed_at: nil }

  after_create_commit :send_whatsapp

  # Cierra la notificación para que ya no le aparezca más al usuario.
  def close!(time: Time.current)
    return if closed_at

    update! closed_at: time
  end

  # Cierra una notificación según un usuario, el objeto que generó la notificación
  # y un evento.
  # Si ya se tiene la notificación, no es necesario pasar por este método, se puede
  # llamar a close! directamente.
  def self.close_by!(event:, notifiable:, user:)
    user
      .notifications
      .active
      .where(event:, notifiable:)
      .first!
      .close!
  end

  # Idéntico a close_by!, solo que no hace nada si la notificación no existe
  def self.close_by(event:, notifiable:, user:)
    user
      .notifications
      .active
      .where(event:, notifiable:)
      .first
      &.close!
  end

  private

  def send_whatsapp
    # TODO: a definir
  end

  def role_belongs_to_user
    errors.add(:role, :invalid) unless user&.roles&.include?(role.to_s)
  end

  def event_exists
    errors.add(:event, :inclusion) unless Notification::Registry.event?(event)
  end
end

# == Schema Information
#
# Table name: notifications
#
#  id                            :bigint           not null, primary key
#  closed_at                     :datetime
#  description                   :string
#  event                         :string           not null
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  title                         :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notifiable_id                 :bigint           not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_notifications_on_notifiable                     (notifiable_type,notifiable_id)
#  index_notifications_on_notification_configuration_id  (notification_configuration_id)
#  index_notifications_on_user_id                        (user_id)
#  index_notifications_one_active_per_event              (notifiable_type,notifiable_id,event,user_id) UNIQUE WHERE (closed_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
