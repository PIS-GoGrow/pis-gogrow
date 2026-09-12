# frozen_string_literal: true

class User < ApplicationRecord
  class DomainNotAllowed < StandardError; end

  has_secure_password

  generates_token_for :email_verification, expires_in: 2.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_many :sessions, dependent: :destroy

  has_one :provider, dependent: :destroy
  has_one :admin, dependent: :destroy
  has_one :consumer, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 12 }
  validates :google_uid, uniqueness: true, allow_nil: true

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  def self.google_allowed_domains
    ENV.fetch("GOOGLE_ALLOWED_DOMAINS", "gmail.com,gogrow.com").split(",").filter_map { it.strip.downcase.presence }
  end

  # Finds or creates the account behind a Google Sign-In, from the payload
  # OmniAuth returns after a successful login (request.env["omniauth.auth"]).
  # A random password satisfies has_secure_password's presence check on
  # create — the account can still set a real one later through the normal
  # "forgot password" flow if it ever wants password-based login too.
  def self.find_or_create_from_google(auth)
    email = auth.info.email.to_s.downcase
    raise DomainNotAllowed unless google_allowed_domains.include?(email.split("@").last)

    user = find_or_initialize_by(email: email)
    user.password = SecureRandom.hex(32) if user.new_record?
    user.name = auth.info.name
    user.google_uid = auth.uid
    user.avatar_url = auth.info.image
    user.save!
    user
  end

  def self.find_from_google(auth)
    email = auth.info.email.to_s.downcase

    find_by email: email
  end

  # Devuelve si el usuario es un proveedor
  # Nota: En general, no habría que usar este método. Habría que consultar:
  #   Current.session.provider?
  # para ver qué rol tiene activo el usuario en esta sesión.
  def provider?
    provider.present?
  end

  # Devuelve si el usuario es un consumidor
  # Nota: En general, no habría que usar este método. Habría que consultar:
  #   Current.session.consumer?
  # para ver qué rol tiene activo el usuario en esta sesión.
  def consumer?
    consumer.present?
  end

  # Devuelve si el usuario es un admin
  # Nota: En general, no habría que usar este método. Habría que consultar:
  #   Current.session.admin?
  # para ver qué rol tiene activo el usuario en esta sesión.
  def admin?
    admin.present?
  end

  # Devuelve qué rol debería ser asignado al usuario, considerando que se está intentando acceder
  # con un requested_role. El rol pedido se otorga si está presente en los roles del usuario.
  # Si no hay ningún rol pedido (requested_role == nil), se otorga el primer rol que tenga el usuario
  # en la lista [provider, consumer, admin].
  def resolve_role(requested_role)
    if (requested_role == :provider || requested_role.nil?) && provider?
      :provider
    elsif (requested_role == :consumer || requested_role.nil?) && consumer?
      :consumer
    elsif (requested_role == :admin || requested_role.nil?) && admin?
      :admin
    else
      nil
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  avatar_url      :string
#  email           :string           not null
#  google_uid      :string
#  name            :string           not null
#  password_digest :string           not null
#  verified        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#
