# frozen_string_literal: true

class TwilioCallbacksController < ApplicationController
  skip_before_action :authenticate
  skip_forgery_protection

  before_action :validate_twilio_signature
  before_action :set_notification

  DELIVERED_STATUSES = %w[delivered read].freeze
  FAIL_STATUSES = %w[failed undelivered].freeze
  NO_RETRY_CODES = %w[63001 63002 63003 63005 63006 63007 63008 63013 63014].freeze

  def callback
    retry_send = false

    @notification.with_lock do
      if DELIVERED_STATUSES.include?(callback_params[:MessageStatus]) && !@notification.delivered?
        @notification.update!(
          delivered_at: Time.current,
          whatsapp_send_status: :delivered
        )
      elsif FAIL_STATUSES.include?(callback_params[:MessageStatus]) && @notification.accepted?
        @notification.delivery_failed!

        if NO_RETRY_CODES.exclude?(callback_params[:ErrorCode])
          retry_send = @notification.send_to_user? && !@notification.send_attempts_exceeded?

          if !@notification.send_to_user? && !@notification.send_attempts_exceeded?
            @notification.skipped!
          end
        end
      end
    end

    WhatsappSenderJob.perform_later(@notification) if retry_send

    head :ok
  end

  private

  def callback_params
    @callback_params ||= params.permit(:MessageSid, :MessageStatus, :ErrorCode)
  end

  def set_notification
    @notification = Notification.find_by(twilio_sid: callback_params[:MessageSid])

    head :ok unless @notification
    Rails.logger.warn("[TwilioCallbacksController] SID de mensaje inválido: #{callback_params[:MessageSid]} " +
                      "con estado #{callback_params[:MessageStatus]}")
  end

  def validate_twilio_signature
    validator = Twilio::Security::RequestValidator.new(ENV.fetch("TWILIO_AUTH_TOKEN"))
    signature = request.headers["X-Twilio-Signature"].to_s

    head :forbidden unless validator.validate(request.original_url, request.POST, signature)
  end
end
