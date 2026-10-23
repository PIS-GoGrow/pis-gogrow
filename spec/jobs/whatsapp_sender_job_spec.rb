# frozen_string_literal: true

require "rails_helper"

RSpec.describe WhatsappSenderJob, type: :job do
  fixtures :users, :notification_configurations, :orders

  include ActiveJob::TestHelper

  EVENT_KEY = :order_created
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

  let(:title_data) { { name: "Ana" } }
  let(:description_data) { { order: "1234", total: "$ 500" } }

  let(:notification) do
    create(
      :notification,
      user: users(:one),
      event: EVENT_KEY.to_s,
      role: users(:one).roles[0],
      notifiable: orders(:upcoming_pending_future),
      notification_configuration: notification_configurations(:one)
    )
  end

  before do
    Notification::Registry.set_data([
      {},
      {
        EVENT_KEY => Notification::Registry::Event.new(
          key: EVENT_KEY,
          configuration_key: :orders,
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
  def rest_error(code)
    response = instance_double(
      Twilio::Response,
      status_code: 400,
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
    described_class.perform_now(notification, EVENT_KEY.to_s, title_data, description_data, PHONE)
  end

  def perform_later_job
    described_class.perform_later(notification, EVENT_KEY.to_s, title_data, description_data, PHONE)
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
        "title_name" => "Ana", "description_order" => "1234", "description_total" => "$ 500"
      )
      expect(variables.keys).to all(match(/\A(title_|description_).+\z/))
    end

    context "cuando title y description comparten nombre de clave" do
      let(:title_data) { { name: "A" } }
      let(:description_data) { { name: "B" } }

      it "conserva ambas claves" do
        messages = stub_twilio(:ok)

        perform_now_job

        expect(JSON.parse(messages.calls.first.fetch(:content_variables)))
          .to eq("title_name" => "A", "description_name" => "B")
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

    it "registra whatsapp_sent_at y deja failed en false" do
      stub_twilio(:ok)

      freeze_time do
        perform_now_job

        notification.reload
        expect(notification.whatsapp_sent_at).to eq(Time.current)
        expect(notification.failed).to be(false)
      end
    end

    it "pone failed en false aunque antes estuviera en true" do
      notification.update!(failed: true)
      stub_twilio(:ok)

      perform_now_job

      expect(notification.reload.failed).to be(false)
    end
  end

  describe "errores transitorios" do
    it "reintenta un RestError con código no permanente, sin tocar failed" do
      stub_twilio(rest_error(30008))

      expect { perform_now_job }.to have_enqueued_job(described_class)

      notification.reload
      expect(notification.whatsapp_sent_at).to be_nil
      expect(notification.failed).not_to be(true)
    end

    it "reintenta un TwilioError genérico (por ejemplo de red)" do
      stub_twilio(Twilio::REST::TwilioError.new("connection reset"))

      expect { perform_now_job }.to have_enqueued_job(described_class)

      expect(notification.reload.failed).not_to be(true)
    end

    it "marca como enviada y no fallada si un reintento tiene éxito" do
      messages = stub_twilio(rest_error(30008), :ok)

      perform_enqueued_jobs { perform_later_job }

      expect(messages.calls.size).to eq(2)
      notification.reload
      expect(notification.whatsapp_sent_at).to be_present
      expect(notification.failed).to be(false)
    end

    it "no marca failed antes de agotar los intentos" do
      messages = stub_twilio(rest_error(30008))

      perform_now_job

      expect(messages.calls.size).to eq(1)
      expect(notification.reload.failed).not_to be(true)
    end

    it "marca la notificación como failed después de agotar los intentos" do
      messages = stub_twilio(rest_error(30008))

      perform_enqueued_jobs do
        # Según cómo esté implementado el agotamiento de reintentos, el error
        # puede propagarse al final; lo que importa acá es el efecto.
        perform_later_job
      rescue described_class::TransientTwilioError
        nil
      end

      expect(messages.calls.size).to eq(MAX_ATTEMPTS)
      notification.reload
      expect(notification.failed).to be(true)
      expect(notification.whatsapp_sent_at).to be_nil
    end
  end

  describe "errores permanentes" do
    described_class::PERMANENT_ERROR_CODES.each do |code|
      it "no reintenta un RestError con código #{code} y marca failed" do
        messages = stub_twilio(rest_error(code))

        expect { perform_now_job }.not_to have_enqueued_job(described_class)

        expect(messages.calls.size).to eq(1)
        notification.reload
        expect(notification.failed).to be(true)
        expect(notification.whatsapp_sent_at).to be_nil
      end
    end

    it "no propaga el error fuera del job" do
      stub_twilio(rest_error(21211))

      expect { perform_now_job }.not_to raise_error
    end
  end
end
