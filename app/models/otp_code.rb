# frozen_string_literal: true

# Código de un solo uso para verificar que quien lo recibe controla el correo
# del usuario. Hay uno por usuario y propósito: pedir otro reemplaza al anterior.
#
# El código no se guarda en ningún lado: se deriva con un HMAC del `nonce` y la
# clave del servidor. Así el mailer, que corre en segundo plano, solo recibe el id
# del registro y la base no tiene nada que sirva para entrar.
class OtpCode < ApplicationRecord
  MAX_ATTEMPTS = 5
  TTL = { "invitation" => 7.days, "password_reset" => 20.minutes }.freeze
  RESEND_COOLDOWN = { "invitation" => 1.minute, "password_reset" => 5.minutes }.freeze

  enum :purpose, { invitation: 0, password_reset: 1 }

  belongs_to :user

  validates :nonce, :expires_at, :sent_at, presence: true

  def self.issue(user, purpose)
    otp = find_or_initialize_by(user: user, purpose: purpose)
    return if otp.persisted? && otp.sent_at > RESEND_COOLDOWN.fetch(otp.purpose).ago

    otp.update!(nonce: SecureRandom.hex(16), expires_at: TTL.fetch(otp.purpose).from_now, attempts: 0, sent_at: Time.current)
    otp
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def self.verify(user, purpose, code)
    otp = find_by(user: user, purpose: purpose)
    return false if otp.nil? || otp.expired?
    return false unless where(id: otp.id).where("attempts < ?", MAX_ATTEMPTS).update_all("attempts = attempts + 1") == 1
    return false unless ActiveSupport::SecurityUtils.secure_compare(otp.code, code.to_s)

    where(id: otp.id).delete_all == 1
  end

  def self.check(user, purpose, code)
    otp = find_by(user: user, purpose: purpose)
    otp.present? && !otp.expired? && ActiveSupport::SecurityUtils.secure_compare(otp.code, code.to_s)
  end

  def self.pending?(user, purpose)
    find_by(user: user, purpose: purpose)&.expired? == false
  end

  def self.consume(user, purpose)
    where(user: user, purpose: purpose).delete_all
  end

  def code
    key = Rails.application.key_generator.generate_key("otp_code")
    digest = OpenSSL::HMAC.digest("SHA256", key, "#{purpose}:#{user_id}:#{nonce}")

    password_reset? ? (digest.unpack1("Q>") % 1_000_000).to_s.rjust(6, "0") : digest.unpack1("H32")
  end

  def expired?
    expires_at <= Time.current
  end
end
