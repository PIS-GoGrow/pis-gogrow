# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  fixtures :users, :companies, :consumers, :orders

  let(:configuration) do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |c|
      c.roles = %w[consumer]
    end
  end

  let(:consumer_user) { users(:one) }
  let(:order) { orders(:upcoming_pending_today) }

  subject(:notification) do
    described_class.new(
      notification_configuration: configuration,
      user: consumer_user,
      role: "consumer",
      event: "order_confirmation",
      requires_action: false,
      notifiable: order,
      title_data: {},
      description_data: {}
    )
  end

  describe "validaciones" do
    it "es válido con todos los atributos requeridos" do
      expect(notification).to be_valid
    end

    it "invalida si el rol no pertenece al usuario" do
      notification.role = "admin"
      expect(notification).not_to be_valid
      expect(notification.errors[:role]).to include("no es válido")
    end

    it "invalida si el evento no está registrado en Notification::Registry" do
      notification.event = "evento_inexistente"
      expect(notification).not_to be_valid
      expect(notification.errors[:event]).to be_present
      expect(notification.errors[:title]).to be_present
      expect(notification.errors[:description]).to be_present
    end

    it "define el enum de whatsapp_send_status con valor por defecto pending" do
      expect(notification.whatsapp_send_status).to eq("pending")
      expect(described_class.whatsapp_send_statuses.keys).to match_array(
        %w[pending skipped sending accepted delivered send_failed delivery_failed]
      )
    end
  end

  describe "resolución de title y description dinámicos" do
    it "resuelve el título y la descripción interpolando title_data y description_data" do
      notification.title_data = { provider: "TuViandita" }
      notification.description_data = { provider: "TuViandita", date: "15/11" }

      expect(notification.title).to be_present
      expect(notification.description).to be_present
    end

    it "siempre devuelve un String y nunca un Hash para eventos con pluralización aunque description_data sea nil o incompleto" do
      notification.event = "coupon_assigned"
      notification.description_data = nil

      expect(notification.description).to be_a(String)
      expect(notification.description).not_to be_a(Hash)
    end

    it "resuelve correctamente eventos pluralizados cuando se pasan todos los parámetros" do
      notification.event = "coupon_assigned"
      notification.description_data = {
        name: "Descuento 50%",
        percentage: 50,
        count: 2,
        period: "15/11/26 al 20/11/26"
      }

      expect(notification.description).to include("2 viandas")
    end
  end

  describe "scopes y métodos de cierre" do
    before { notification.save! }

    it "filtra activas y cerradas correctamente" do
      expect(described_class.active).to include(notification)
      expect(described_class.closed).not_to include(notification)

      notification.close!

      expect(described_class.active).not_to include(notification)
      expect(described_class.closed).to include(notification)
    end

    it "close! no sobreescribe closed_at si ya estaba cerrada" do
      initial_time = 1.hour.ago.change(usec: 0)
      notification.update!(closed_at: initial_time)

      expect { notification.close! }.not_to change { notification.reload.closed_at }
    end
  end

  describe "integridad de base de datos" do
    it "previene duplicar notificaciones activas para el mismo evento, notifiable y usuario" do
      notification.save!

      duplicate = described_class.new(
        notification_configuration: configuration,
        user: consumer_user,
        role: "consumer",
        event: "order_confirmation",
        requires_action: false,
        notifiable: order,
        title_data: {},
        description_data: {}
      )

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "send_to_user" do
    before do
      configuration.users << consumer_user
      consumer_user.phone = "+59898123456"
    end

    it "deja pasar una notificación válida" do
      expect(notification.send_to_user?).to be(true)
    end

    it "previene enviar notificaciones cuando el usuario no tiene teléfono" do
      consumer_user.phone = nil

      expect(notification.send_to_user?).to be(false)
    end

    it "previene enviar notificaciones cuando la configuración está desactivada" do
      configuration.users.destroy consumer_user

      expect(notification.send_to_user?).to be(false)
    end

    it "envía cuando la configuración no es configurable" do
      configuration.users.destroy consumer_user
      configuration.configurable = false

      expect(notification.send_to_user?).to be(true)
    end

    it "previene enviar notificaciones cuando fue cerrada" do
      notification.closed_at = Time.current

      expect(notification.send_to_user?).to be(false)
    end

    it "previene enviar notificaciones a un proveedor cerrado" do
      notification.user = users(:provider_user)
      users(:provider_user).provider.closures.create!(
        starts_on: Date.current,
        ends_on: Date.current,
        reason: "Motivo"
      )

      expect(notification.send_to_user?).to be(false)
    end
  end

  describe "send_attempts_exceeded" do
    it "devuelve false cuando la cantidad de intentos es menor al máximo" do
      notification.whatsapp_send_attempts = Notification::MAX_SEND_ATTEMPTS - 1

      expect(notification.send_attempts_exceeded?).to be(false)
    end

    it "previene enviar notificaciones cuando se hicieron muchos intentos" do
      notification.whatsapp_send_attempts = Notification::MAX_SEND_ATTEMPTS

      expect(notification.send_attempts_exceeded?).to be(true)
    end
  end
end

# == Schema Information
#
# Table name: notifications
#
#  id                            :bigint           not null, primary key
#  closed_at                     :datetime
#  delivered_at                  :datetime
#  description_data              :json
#  event                         :string           not null
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  title_data                    :json
#  twilio_sid                    :string
#  whatsapp_last_sent_at         :datetime
#  whatsapp_send_attempts        :integer          default(0)
#  whatsapp_send_status          :integer
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
#  index_notifications_on_twilio_sid                     (twilio_sid)
#  index_notifications_on_user_id                        (user_id)
#  index_notifications_one_active_per_event              (notifiable_type,notifiable_id,event,user_id) UNIQUE WHERE (closed_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
