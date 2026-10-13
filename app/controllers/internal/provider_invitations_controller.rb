# frozen_string_literal: true

module Internal
  class ProviderInvitationsController < ActionController::API
    before_action :authenticate_token

    rate_limit to: 20, within: 1.minute, store: Rails.configuration.x.rate_limit_store || Rails.cache,
               with: -> { head :too_many_requests }

    def create
      company = params[:company_id].present? ? Company.find(params[:company_id]) : Company.first!
      Providers::Invite.call(name: params.require(:name), email: params.require(:email), company: company)
      head :created
    rescue Providers::Invite::EmailTaken
      render_error "Ya existe un usuario con ese correo", :unprocessable_content
    rescue ActiveRecord::RecordNotFound
      render_error "Empresa no encontrada", :not_found
    rescue ActionController::ParameterMissing => e
      render_error "Falta el parámetro #{e.param}", :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      render_error e.record.errors.full_messages.to_sentence, :unprocessable_content
    end

    private

    def render_error(message, status)
      render json: { errors: [ message ], message: message }, status: status
    end

    def authenticate_token
      expected = ENV["MOTOR_ADMIN_API_TOKEN"].presence
      return head :not_found unless expected

      provided = request.authorization.to_s.delete_prefix("Bearer ")
      head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
    end
  end
end
