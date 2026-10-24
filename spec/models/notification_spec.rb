# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  fixtures :users, :consumers, :providers

  describe "#send_to_user?" do
    let(:consumer_user) { consumers(:one).user }
    let(:provider) { providers(:tuviandita) }

    def notification_for(user, event:)
      registry_event = Notification::Registry.event!(event)

      described_class.new(
        user:,
        event:,
        role: registry_event.role,
        notification_configuration: Notification::Configuration.find_by!(key: registry_event.configuration_key.to_s)
      )
    end

    before do
      consumer_user.update!(phone: "+59899123456")
      provider.user.update!(phone: "+59899654321")
    end

    it "no envía si el usuario no tiene teléfono" do
      consumer_user.update!(phone: nil)

      expect(notification_for(consumer_user, event: "debt_threshold_exceeded").send_to_user?).to be(false)
    end

    it "envía un evento de un grupo no configurable sin suscripción" do
      expect(notification_for(consumer_user, event: "debt_threshold_exceeded").send_to_user?).to be(true)
    end

    it "no envía un evento de un grupo configurable si el usuario no está suscrito" do
      expect(notification_for(consumer_user, event: "order_confirmation").send_to_user?).to be(false)
    end

    it "envía un evento de un grupo configurable si el usuario está suscrito" do
      Notification::Configuration.find_by!(key: "order_updates").users << consumer_user

      expect(notification_for(consumer_user, event: "order_confirmation").send_to_user?).to be(true)
    end

    context "con un proveedor suscrito" do
      before { Notification::Configuration.find_by!(key: "provider_orders").users << provider.user }

      it "envía si el proveedor abre hoy" do
        expect(notification_for(provider.user, event: "order_received").send_to_user?).to be(true)
      end

      it "no envía si el proveedor cierra hoy" do
        provider.closures.create!(starts_on: Date.current, ends_on: Date.current + 1, reason: "Vacaciones")

        expect(notification_for(provider.user, event: "order_received").send_to_user?).to be(false)
      end
    end
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
#  failed                        :boolean
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  title                         :string
#  whatsapp_sent_at              :datetime
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
