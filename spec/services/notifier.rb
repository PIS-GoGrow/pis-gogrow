# frozen_string_literal: true

# spec/services/notifier_spec.rb
require "rails_helper"

RSpec.describe Notifier do
  fixtures :users, :orders

  let(:user)       { users(:one) }
  let(:notifiable) { orders(:upcoming_pending_future) }
  let(:event_key)  { :order_confirmation }

  let(:registry_configuration) do
    Notification::Registry::Configuration.new(key: :order_updates, roles: [ :consumer ])
  end

  let(:event_role)      { :consumer }
  let(:requires_action) { false }

  let(:registry_event) do
    Notification::Registry::Event.new(
      key: :order_confirmation,
      configuration_key: :order_updates,
      role: event_role,
      requires_action: requires_action
    )
  end

  let!(:configuration) do
    create(:notification_configuration, key: "order_updates", roles: %w[consumer])
  end

  before do
    Notification::Registry.set_data([
      { order_updates: registry_configuration },
      { order_confirmation: registry_event }
    ])
  end

  after { Notification::Registry.set_data(nil) }

  let(:params) { { event_key: event_key, user: user, notifiable: notifiable } }

  describe ".call" do
    context "con un evento registrado y su configuración sincronizada" do
      it "crea una notificación" do
        expect { described_class.call(**params) }
          .to change(Notification, :count).by(1)
      end

      it "devuelve la notificación creada y persistida" do
        notification = described_class.call(**params)

        expect(notification).to be_a(Notification)
        expect(notification).to be_persisted
      end

      it "asocia la notificación al usuario y al notifiable" do
        notification = described_class.call(**params)

        expect(notification.user).to eq(user)
        expect(notification.notifiable).to eq(notifiable)
      end

      it "guarda la clave del evento" do
        notification = described_class.call(**params)

        expect(notification.event.to_s).to eq("order_confirmation")
      end

      it "asocia la Notification::Configuration correspondiente a configuration_key" do
        notification = described_class.call(**params)

        expect(notification.notification_configuration).to eq(configuration)
      end

      it "acepta la clave del evento como string" do
        expect { described_class.call(**params, event_key: "order_confirmation") }
          .to change(Notification, :count).by(1)
      end
    end

    describe "rol" do
      %i[consumer provider admin].each do |role|
        context "cuando el evento está definido para #{role}" do
          let(:event_role) { role }
          let(:registry_configuration) do
            Notification::Registry::Configuration.new(key: :order_updates, roles: [ role ])
          end
          let!(:configuration) do
            create(:notification_configuration, key: "order_updates", roles: [ role.to_s ])
          end

          it "crea la notificación con el rol del evento" do
            notification = described_class.call(**params)

            expect(notification.role.to_s).to eq(role.to_s)
          end
        end
      end
    end

    describe "requires_action" do
      context "cuando el evento no requiere acción" do
        let(:requires_action) { false }

        it "crea una notificación que no requiere acción" do
          expect(described_class.call(**params).requires_action).to be(false)
        end
      end

      context "cuando el evento requiere acción" do
        let(:requires_action) { true }

        it "crea una notificación que requiere acción" do
          expect(described_class.call(**params).requires_action).to be(true)
        end
      end
    end

    describe "title_data y description_data" do
      before do
        I18n.backend.store_translations(
          :es,
          notifications: {
            order_confirmation: {
              title: "Pedido %{order_number} confirmado",
              description: "Tu pedido de %{store} fue confirmado"
            }
          }
        )
      end

      # SUPUESTO: Notification expone #title y #description ya interpolados.
      # Si guarda title_data/description_data, testear esos atributos.
      it "interpola title_data en el título" do
        notification = described_class.call(
          **params,
          title_data: { order_number: "1234" },
          description_data: { store: "Ferretería Sur" }
        )

        expect(notification.title).to eq("Pedido 1234 confirmado")
      end

      it "interpola description_data en la descripción" do
        notification = described_class.call(
          **params,
          title_data: { order_number: "1234" },
          description_data: { store: "Ferretería Sur" }
        )

        expect(notification.description).to eq("Tu pedido de Ferretería Sur fue confirmado")
      end
    end

    describe "errores de configuración" do
      context "cuando el evento no está definido en el Registry" do
        it "lanza Notification::Registry::UnknownEvent" do
          expect {
            described_class.call(**params, event_key: :evento_inexistente)
          }.to raise_error(Notification::Registry::UnknownEvent)
        end

        it "no crea ninguna notificación" do
          expect {
            described_class.call(**params, event_key: :evento_inexistente) rescue nil
          }.not_to change(Notification, :count)
        end
      end

      # La configuración está en el Registry pero no se corrió `notifications:sync`,
      # por lo que no existe en la base de datos.
      context "cuando la configuración del evento no existe en la base de datos" do
        before { configuration.destroy! }

        it "lanza MissingConfiguration" do
          expect { described_class.call(**params) }
            .to raise_error(Notifier::MissingConfiguration)
        end

        it "no crea ninguna notificación" do
          expect {
            described_class.call(**params) rescue nil
          }.not_to change(Notification, :count)
        end
      end
    end

    describe "unicidad por evento, usuario y notifiable" do
      before { described_class.call(**params) }

      # SUPUESTO: no se crea un duplicado en silencio. Si Notifier deja subir el
      # error del índice único, cambiar por raise_error(ActiveRecord::RecordNotUnique).
      it "no crea una segunda notificación activa para el mismo evento, usuario y notifiable" do
        expect { described_class.call(**params) }
          .to raise_error(ActiveRecord::RecordNotUnique)
      end

      it "permite notificar al mismo usuario por el mismo evento sobre otro notifiable" do
        expect { described_class.call(**params, notifiable: orders(:upcoming_pending_today)) }
          .to change(Notification, :count).by(1)
      end

      it "permite notificar a otro usuario por el mismo evento y notifiable" do
        expect { described_class.call(**params, user: users(:other_consumer_user)) }
          .to change(Notification, :count).by(1)
      end

      it "permite notificar de nuevo cuando la anterior ya fue cerrada" do
        Notification.close_by!(event: event_key, notifiable: notifiable, user: user)

        expect { described_class.call(**params) }
          .to change(Notification, :count).by(1)
      end
    end
  end
end
