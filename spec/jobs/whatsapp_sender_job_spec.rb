# frozen_string_literal: true

require "rails_helper"

RSpec.describe WhatsappSenderJob, type: :job do
  fixtures :users, :orders

  include ActiveJob::TestHelper

  EVENT_KEY = :order_confirmation
  CONTENT_SID = "HX0123456789abcdef".freeze
  PHONE = "+59899123456".freeze
  MAX_ATTEMPTS = 6 # 1 intento + 5 reintentos (retry_on attempts: 6)

  # Doble de `client.messages`: registra cada llamada a `create` y devuelve o
  # levanta las respuestas programadas, en orden. La última se repite.
  let(:fake_messages_class) do
    Class.new do
      attr_reader :calls

      def initialize(responses)
        @responses = responses
        @calls = []
      end

      def create(**kwargs)
        @calls << kwargs
        response = @responses.size > 1 ? @responses.shift : @responses.first
        raise response if response.is_a?(Exception)
        response
      end
    end
  end

  let(:fake_message_class) do
    Data.define(:sid)
  end

  let(:title_data) { {} }
  let(:description_data) { { date: "12/12", provider: "TuViandita" } }

  let(:notification) do
    create(
      :notification,
      user: users(:one),
      event: EVENT_KEY.to_s,
      title_data:,
      description_data:,
      role: users(:one).roles[0],
      whatsapp_send_status: :pending,
      notifiable: orders(:upcoming_pending_future),
      notification_configuration: Notification::Configuration.find_by!(key: "order_updates")
    )
  end

  before do
    users(:one).update phone: PHONE
    users(:one).notification_configurations << notification.notification_configuration
    Notification::Registry.set_data([
      {},
      {
        EVENT_KEY => Notification::Registry::Event.new(
          key: EVENT_KEY,
          configuration_key: :order_updates,
          role: "consumer",
          requires_action: false,
          content_sid: CONTENT_SID
        )
      }
    ])
  end

  after do
    # Fuerza a que el Registry vuelva a cargar el archivo real
    Notification::Registry.set_data(nil)
  end

  # Un RestError con el código dado. En las versiones actuales de twilio-ruby el
  # constructor es RestError.new(message, response) y toma el código, el status y
  # el resto de los datos del cuerpo de la respuesta.
  def rest_error(code, status: 400)
    response = instance_double(
      Twilio::Response,
      status_code: status,
      body: {
        "code" => code,
        "message" => "Twilio error #{code}",
        "more_info" => "https://www.twilio.com/docs/errors/#{code}",
        "details" => nil
      }
    )
    Twilio::REST::RestError.new("Twilio error #{code}", response)
  end

  # Reemplaza Twilio::REST::Client.new por un cliente falso. `responses` es una
  # lista de :ok o de excepciones, consumida en orden (la última se repite).
  # Devuelve el fake de messages para inspeccionar las llamadas.
  def stub_twilio(*responses)
    messages = fake_messages_class.new(responses.map { |r| r == :ok ? fake_message_class.new(sid: "a") : r })
    client = Struct.new(:messages).new(messages)
    allow(Twilio::REST::Client).to receive(:new).and_return(client)
    messages
  end

  def perform_now_job
    described_class.perform_now(notification)
  end

  def perform_later_job
    described_class.perform_later(notification)
  end

  describe "envío exitoso" do
    it "envía el mensaje con el content SID del evento y el teléfono destino" do
      messages = stub_twilio(:ok)

      perform_now_job

      expect(messages.calls.size).to eq(1)
      call = messages.calls.first
      expect(call[:content_sid]).to eq(CONTENT_SID)
      expect(call[:to]).to include(PHONE)
      expect(call[:from]).to include(ENV.fetch("TWILIO_PHONE"))
    end

    it "construye el cliente de Twilio con las credenciales del ENV" do
      stub_twilio(:ok)

      perform_now_job

      expect(Twilio::REST::Client).to have_received(:new)
        .with(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
    end

    it "pasa content_variables como JSON con prefijos title_ y description_" do
      messages = stub_twilio(:ok)

      perform_now_job

      variables = JSON.parse(messages.calls.first.fetch(:content_variables))
      expect(variables).to eq(
        "description_date" => "12/12", "description_provider" => "TuViandita"
      )
      expect(variables.keys).to all(match(/\A(title_|description_).+\z/))
    end

    context "cuando title y description comparten nombre de clave" do
      let(:title_data) { { provider: "A" } }

      it "conserva ambas claves" do
        messages = stub_twilio(:ok)

        perform_now_job

        expect(JSON.parse(messages.calls.first.fetch(:content_variables)))
          .to include("title_provider" => "A", "description_provider" => "TuViandita")
      end
    end

    context "con valores que no son texto" do
      let(:description_data) { { date: "12/12", provider: 2, count: 3 } }

      it "los manda como texto" do
        messages = stub_twilio(:ok)

        perform_now_job

        expect(JSON.parse(messages.calls.first.fetch(:content_variables)))
          .to include("description_provider" => "2", "description_count" => "3")
      end
    end

    context "con title_data o description_data nulos" do
      let(:title_data) { nil }
      let(:description_data) { nil }

      it "manda un hash vacío sin fallar" do
        messages = stub_twilio(:ok)

        expect { perform_now_job }.not_to raise_error
        expect(JSON.parse(messages.calls.first.fetch(:content_variables))).to eq({})
      end
    end

    context "con un evento con plantillas en singular y plural" do
      before do
        Notification::Registry.set_data([
          {},
          {
            EVENT_KEY => Notification::Registry::Event.new(
              key: EVENT_KEY,
              configuration_key: :order_updates,
              role: "consumer",
              requires_action: false,
              content_sid: { one: "HXsingular", other: "HXplural" }
            )
          }
        ])
      end

      { 1 => "HXsingular", 3 => "HXplural" }.each do |count, content_sid|
        context "y count #{count}" do
          let(:description_data) { { date: "12/12", provider: 2, count: } }

          it "usa la plantilla #{content_sid}" do
            messages = stub_twilio(:ok)

            perform_now_job

            expect(messages.calls.first[:content_sid]).to eq(content_sid)
          end
        end
      end
    end

    context "sin datos extra" do
      let(:title_data) { {} }
      let(:description_data) { {} }

      it "manda un JSON de objeto vacío" do
        messages = stub_twilio(:ok)

        perform_now_job

        expect(JSON.parse(messages.calls.first.fetch(:content_variables))).to eq({})
      end
    end

    it "registra whatsapp_last_sent_at y deja en accepted" do
      stub_twilio(:ok)

      freeze_time do
        perform_now_job

        notification.reload
        expect(notification.whatsapp_last_sent_at).to eq(Time.current)
        expect(notification.whatsapp_send_status).to eq("accepted")
      end
    end

    it "pone accepted aunque antes estuviera en delivery_failed" do
      notification.update!(whatsapp_send_status: :delivery_failed)
      stub_twilio(:ok)

      perform_now_job

      expect(notification.reload.whatsapp_send_status).to eq("accepted")
    end
  end

  describe "cancelación y condiciones de carrera" do
    it "marca como skipped si send_to_user? es false y no llama a Twilio" do
      messages = stub_twilio(:ok)
      users(:one).update!(phone: nil)

      perform_now_job

      expect(messages.calls).to be_empty
      expect(notification.reload.whatsapp_send_status).to eq("skipped")
    end

    it "no envía si la notificación ya fue entregada" do
      messages = stub_twilio(:ok)
      notification.update!(whatsapp_send_status: :delivered)

      perform_now_job

      expect(messages.calls).to be_empty
    end

    it "no sobreescribe con accepted si un callback marca delivered durante la llamada a Twilio" do
      messages = fake_messages_class.new([ fake_message_class.new(sid: "sid_123") ])
      allow(messages).to receive(:create) do
        notification.update!(whatsapp_send_status: :delivered)
        fake_message_class.new(sid: "sid_123")
      end
      client = Struct.new(:messages).new(messages)
      allow(Twilio::REST::Client).to receive(:new).and_return(client)

      perform_now_job

      notification.reload
      expect(notification.whatsapp_send_status).to eq("delivered")
      expect(notification.twilio_sid).to eq("sid_123")
    end

    it "pasa el status_callback configurado a Twilio" do
      messages = stub_twilio(:ok)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_STATUS_CALLBACK_URL").and_return("https://callback.example.com/twilio")

      perform_now_job

      expect(messages.calls.first[:status_callback]).to eq("https://callback.example.com/twilio")
    end

    it "no pasa status_callback si es localhost" do
      messages = stub_twilio(:ok)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_STATUS_CALLBACK_URL").and_return("http://localhost:3001")

      perform_now_job

      expect(messages.calls.first).not_to have_key(:status_callback)
    end
  end

  describe "entorno de desarrollo" do
    it "no envía si Rails.env es development y TWILIO_DELIVERY_ENABLED no es true" do
      allow(Rails.env).to receive(:development?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_DELIVERY_ENABLED").and_return("false")
      messages = stub_twilio(:ok)

      perform_now_job

      expect(messages.calls).to be_empty
      expect(notification.reload.whatsapp_send_status).to eq("pending")
    end
  end

  describe "errores transitorios" do
    it "reintenta un RestError 5xx, sin tocar failed" do
      stub_twilio(rest_error(20500, status: 500))

      expect { perform_now_job }.to have_enqueued_job(described_class)

      notification.reload
      expect(notification.whatsapp_last_sent_at).to be_nil
      expect(notification.whatsapp_send_status).not_to eq("send_failed")
    end

    it "reintenta un RestError 429" do
      stub_twilio(rest_error(20429, status: 429))

      expect { perform_now_job }.to have_enqueued_job(described_class)
    end

    it "reintenta un TwilioError genérico (por ejemplo de red)" do
      stub_twilio(Twilio::REST::TwilioError.new("connection reset"))

      expect { perform_now_job }.to have_enqueued_job(described_class)

      expect(notification.reload.whatsapp_send_status).not_to eq("send_failed")
    end

    it "marca como enviada y aceptada si un reintento tiene éxito" do
      messages = stub_twilio(rest_error(20500, status: 500), :ok)

      perform_enqueued_jobs { perform_later_job }

      expect(messages.calls.size).to eq(2)
      notification.reload
      expect(notification.whatsapp_last_sent_at).to be_present
      expect(notification.whatsapp_send_status).to eq("accepted")
    end

    it "no marca failed antes de agotar los intentos" do
      messages = stub_twilio(rest_error(20500, status: 500))

      perform_now_job

      expect(messages.calls.size).to eq(1)
      expect(notification.reload.whatsapp_send_status).to eq("sending")
    end

    it "marca la notificación como failed después de agotar los intentos" do
      messages = stub_twilio(rest_error(20500, status: 500))

      perform_enqueued_jobs do
        # Según cómo esté implementado el agotamiento de reintentos, el error
        # puede propagarse al final; lo que importa acá es el efecto.
        perform_later_job
      rescue described_class::TransientTwilioError
        nil
      end

      expect(messages.calls.size).to eq(MAX_ATTEMPTS)
      notification.reload
      expect(notification.whatsapp_send_status).to eq("send_failed")
      expect(notification.whatsapp_last_sent_at).to be_nil
    end
  end

  describe "errores permanentes" do
    { 21211 => 400, 20003 => 401, 21656 => 400, 20404 => 404 }.each do |code, status|
      it "no reintenta un RestError #{status} (código #{code}) y marca failed" do
        messages = stub_twilio(rest_error(code, status:))

        expect { perform_now_job }.not_to have_enqueued_job(described_class)

        expect(messages.calls.size).to eq(1)
        notification.reload
        expect(notification.whatsapp_send_status).to eq("send_failed")
        expect(notification.whatsapp_last_sent_at).to be_nil
      end
    end

    it "no propaga el error fuera del job" do
      stub_twilio(rest_error(21211))

      expect { perform_now_job }.not_to raise_error
    end
  end
end
