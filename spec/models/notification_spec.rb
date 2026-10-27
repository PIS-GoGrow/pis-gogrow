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
      title: "Tu pedido fue confirmado",
      description: "Tu pedido fue confirmado."
    )
  end

  describe "validaciones" do
    it "es válido con todos los atributos requeridos" do
      expect(notification).to be_valid
    end

    it "requiere presencia de title" do
      notification.title = nil
      expect(notification).not_to be_valid
      expect(notification.errors[:title]).to be_present
    end

    it "requiere presencia de description" do
      notification.description = nil
      expect(notification).not_to be_valid
      expect(notification.errors[:description]).to be_present
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
        title: "Otro título",
        description: "Otra descripción"
      )

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
