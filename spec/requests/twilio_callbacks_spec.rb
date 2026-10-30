# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TwilioCallbacks", type: :request do
  fixtures :users, :orders

  EVENT_KEY = :order_confirmation

  # Ajustá la ruta y el factory a los de tu app
  let(:path) { "/twilio-callback" }
  let(:sid) { "SM1234567890" }

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
      whatsapp_send_status: :accepted,
      notifiable: orders(:upcoming_pending_future),
      twilio_sid: sid,
      notification_configuration: Notification::Configuration.find_by!(key: "order_updates")
    )
  end

  let(:params) { { MessageSid: sid, MessageStatus: "delivered" } }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("TWILIO_AUTH_TOKEN").and_return("test_token")
    allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(true)
    notification # fuerza la creación
  end

  def post_callback(overrides = {})
    post path, params: params.merge(overrides)
  end

  describe "firma de Twilio" do
    it "responde 403 si la firma es inválida" do
      allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_return(false)

      post_callback

      expect(response).to have_http_status(:forbidden)
      expect(notification.reload.whatsapp_send_status).to eq("accepted")
    end

    it "acepta una firma válida calculada con el auth token" do
      allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_call_original

      validator = Twilio::Security::RequestValidator.new("test_token")
      body = params.stringify_keys
      signature = validator.build_signature_for("http://www.example.com#{path}", body)

      post path, params: params, headers: { "X-Twilio-Signature" => signature }

      expect(response).to have_http_status(:ok)
      expect(notification.reload.whatsapp_send_status).to eq("delivered")
    end

    it "responde 403 si falta el header de firma" do
      allow_any_instance_of(Twilio::Security::RequestValidator).to receive(:validate).and_call_original

      post path, params: params

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "notificación inexistente" do
    it "responde 200 y no hace nada" do
      expect {
        post_callback(MessageSid: "SM_NO_EXISTE")
      }.not_to have_enqueued_job(WhatsappSenderJob)

      expect(response).to have_http_status(:ok)
      expect(notification.reload.whatsapp_send_status).to eq("accepted")
    end
  end

  describe "estado delivered / read" do
    %w[delivered read].each do |status|
      it "marca la notificación como delivered con MessageStatus=#{status}" do
        freeze_time do
          post_callback(MessageStatus: status)

          notification.reload
          expect(response).to have_http_status(:ok)
          expect(notification.whatsapp_send_status).to eq("delivered")
          expect(notification.delivered_at).to eq(Time.current)
        end
      end
    end

    it "no pisa delivered_at si ya estaba entregada" do
      delivered_at = 1.hour.ago.change(usec: 0)
      notification.update!(whatsapp_send_status: :delivered, delivered_at: delivered_at)

      post_callback(MessageStatus: "read")

      expect(response).to have_http_status(:ok)
      expect(notification.reload.delivered_at).to eq(delivered_at)
    end

    it "no encola reintentos" do
      expect { post_callback }.not_to have_enqueued_job(WhatsappSenderJob)
    end
  end

  describe "estado failed / undelivered" do
    %w[failed undelivered].each do |status|
      context "con MessageStatus=#{status}" do
        before do
          allow_any_instance_of(Notification).to receive(:send_to_user?).and_return(true)
          allow_any_instance_of(Notification).to receive(:send_attempts_exceeded?).and_return(false)
        end

        it "marca la entrega como fallida y reintenta el envío" do
          expect {
            post_callback(MessageStatus: status, ErrorCode: "30008")
          }.to have_enqueued_job(WhatsappSenderJob).with(notification)

          expect(response).to have_http_status(:ok)
          expect(notification.reload.whatsapp_send_status).to eq("delivery_failed")
        end
      end
    end

    context "con ErrorCode que no admite reintento" do
      %w[63001 63002 63003 63005 63006 63007 63008 63013 63014].each do |code|
        it "no reintenta con ErrorCode=#{code}" do
          allow_any_instance_of(Notification).to receive(:send_to_user?).and_return(true)
          allow_any_instance_of(Notification).to receive(:send_attempts_exceeded?).and_return(false)

          expect {
            post_callback(MessageStatus: "failed", ErrorCode: code)
          }.not_to have_enqueued_job(WhatsappSenderJob)

          expect(response).to have_http_status(:ok)
          expect(notification.reload.whatsapp_send_status).to eq("delivery_failed")
        end
      end
    end

    context "cuando se superaron los intentos de envío" do
      before do
        allow_any_instance_of(Notification).to receive(:send_to_user?).and_return(true)
        allow_any_instance_of(Notification).to receive(:send_attempts_exceeded?).and_return(true)
      end

      it "marca delivery_failed y no reintenta" do
        expect {
          post_callback(MessageStatus: "failed", ErrorCode: "30008")
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(notification.reload.whatsapp_send_status).to eq("delivery_failed")
      end
    end

    context "cuando no se debe enviar al usuario (send_to_user? es false)" do
      before do
        allow_any_instance_of(Notification).to receive(:send_to_user?).and_return(false)
      end

      it "marca la notificación como skipped si no se superaron los intentos" do
        allow_any_instance_of(Notification).to receive(:send_attempts_exceeded?).and_return(false)

        expect {
          post_callback(MessageStatus: "failed", ErrorCode: "30008")
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(notification.reload.whatsapp_send_status).to eq("skipped")
      end

      it "queda en delivery_failed si se superaron los intentos" do
        allow_any_instance_of(Notification).to receive(:send_attempts_exceeded?).and_return(true)

        expect {
          post_callback(MessageStatus: "failed", ErrorCode: "30008")
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(notification.reload.whatsapp_send_status).to eq("delivery_failed")
      end
    end

    context "cuando la notificación no estaba en accepted" do
      before { notification.update!(whatsapp_send_status: :delivered) }

      it "ignora el callback" do
        expect {
          post_callback(MessageStatus: "failed", ErrorCode: "30008")
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(response).to have_http_status(:ok)
        expect(notification.reload.whatsapp_send_status).to eq("delivered")
      end
    end
  end

  describe "otros estados" do
    %w[queued sent sending].each do |status|
      it "ignora MessageStatus=#{status} y responde 200" do
        expect {
          post_callback(MessageStatus: status)
        }.not_to have_enqueued_job(WhatsappSenderJob)

        expect(response).to have_http_status(:ok)
        expect(notification.reload.whatsapp_send_status).to eq("accepted")
      end
    end
  end
end
