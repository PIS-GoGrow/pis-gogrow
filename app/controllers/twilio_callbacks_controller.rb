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
    if DELIVERED_STATUSES.include?(callback_params[:MessageStatus])
      @notification.update!(delivered_at: Time.current, failed: false) if @notification.delivered_at.nil?
    elsif FAIL_STATUSES.include?(callback_params[:MessageStatus]) && @notification.delivered_at.nil?
      @notification.update! failed: true

      # send_to_user? ya tiene en cuenta la cantidad máxima de reintentos posibles
      # WhatsappSenderJob actualiza la cantidad de envíos
      if NO_RETRY_CODES.exclude?(callback_params[:ErrorCode]) && notification.send_to_user?
        WhatsappSenderJob.perform_later(@notification)
      end
    end

    head :ok
  end

  private

  def callback_params
    @callback_params ||= params.permit(:MessageSid, :MessageStatus, :ErrorCode)
  end

  def set_notification
    @notification = Notification.find_by(twilio_sid: callback_params[:MessageSid])
    head :ok unless @notification
  end

  def validate_twilio_signature
    validator = Twilio::Security::RequestValidator.new(ENV.fetch("TWILIO_AUTH_TOKEN"))
    signature = request.headers["X-Twilio-Signature"].to_s

    head :forbidden unless validator.validate(request.original_url, request.POST, signature)
  end
end
