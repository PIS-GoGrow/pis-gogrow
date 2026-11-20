# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users, :consumers, :admins, :providers, :companies
  describe "provider password policy" do
    let(:user) { users(:provider_user) }

    def save_with(password, confirmation = password)
      user.assign_attributes(password: password, password_confirmation: confirmation)
      user.save(context: :provider_password)
    end

    it "accepts a long password with an uppercase letter, a number and a special character" do
      expect(save_with("Nueva-Clave-2026-ok!")).to be(true)
    end

    it "rejects a password that is too short even if it has everything else" do
      expect(save_with("Aa1!aaaaaaaaaaa")).to be(false)
      expect(user.errors.where(:password, :provider_policy)).to be_present
    end

    it "rejects a password without an uppercase letter, a number or a special character" do
      [ "nueva-clave-2026-ok!", "Nueva-Clave-Segura-ok!", "NuevaClave2026okayy" ].each do |weak|
        expect(save_with(weak)).to be(false)
      end
    end

    it "rejects a blank password instead of silently keeping the old one" do
      expect(save_with("")).to be(false)
      expect(user.errors.where(:password, :blank)).to be_present
    end

    it "only applies in the provider context" do
      user.assign_attributes(password: "Doce-chars-ok1", password_confirmation: "Doce-chars-ok1")

      expect(user.save).to be(true)
    end
  end

  describe "phone" do
    it "guarda un celular uruguayo sin código de país en formato internacional" do
      expect(User.new(phone: "099 123 456").phone).to eq("+59899123456")
    end

    it "respeta el código de país de un celular extranjero" do
      expect(User.new(phone: "+54 9 11 2345-6789").phone).to eq("+5491123456789")
    end

    it "guarda nil si se deja vacío" do
      expect(User.new(phone: " ").phone).to be_nil
    end

    [ "2900 1234", "1234567", "llamame" ].each do |phone|
      it "rechaza #{phone.inspect}" do
        user = User.new(phone:)

        user.validate

        expect(user.errors[:phone]).to be_present
      end
    end
  end

  describe ".find_and_update_from_google" do
    def build_auth(email:, uid: "google-uid-123", image: "https://example.com/avatar.png")
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: uid,
        info: OmniAuth::AuthHash::InfoHash.new(
          email: email,
          name: "Test User",
          image: image
        )
      )
    end

    let(:user) { users(:one) }

    before do
      user.update!(email: "test-oauth@gmail.com", google_uid: nil, avatar_url: nil)
    end

    it "asigna google_uid y avatar_url en el primer login cuando no existen" do
      auth = build_auth(email: user.email, uid: "new-uid-100", image: "https://lh3.googleusercontent.com/avatar.jpg")

      result = User.find_and_update_from_google(auth)

      expect(result).to eq(user)
      expect(user.reload.google_uid).to eq("new-uid-100")
      expect(user.avatar_url).to eq("https://lh3.googleusercontent.com/avatar.jpg")
    end

    it "no sobreescribe el avatar_url si el usuario ya tiene uno cargado previamente" do
      user.update!(avatar_url: "https://custom.cdn.com/manual-avatar.png")
      auth = build_auth(email: user.email, uid: "new-uid-100", image: "https://lh3.googleusercontent.com/avatar.jpg")

      result = User.find_and_update_from_google(auth)

      expect(result).to eq(user)
      expect(user.reload.avatar_url).to eq("https://custom.cdn.com/manual-avatar.png")
      expect(user.google_uid).to eq("new-uid-100")
    end

    it "encuentra directamente al usuario por google_uid en logins posteriores" do
      user.update!(google_uid: "existing-google-uid-555")
      auth = build_auth(email: user.email, uid: "existing-google-uid-555")

      result = User.find_and_update_from_google(auth)

      expect(result).to eq(user)
    end

    it "lanza GoogleUidMismatch si el usuario existe por email pero tiene un google_uid diferente" do
      user.update!(google_uid: "original-registered-uid")
      auth = build_auth(email: user.email, uid: "hacked-or-changed-uid")

      expect {
        User.find_and_update_from_google(auth)
      }.to raise_error(User::GoogleUidMismatch)
    end

    it "lanza DomainNotAllowed si el dominio de correo no pertenece a los permitidos" do
      auth = build_auth(email: "malicious@unauthorized-domain.com")

      expect {
        User.find_and_update_from_google(auth)
      }.to raise_error(User::DomainNotAllowed)
    end

    it "retorna nil si el usuario no existe ni por uid ni por email en la base de datos" do
      auth = build_auth(email: "nonexistent-user@gmail.com", uid: "unknown-uid")

      expect(User.find_and_update_from_google(auth)).to be_nil
    end

    it "normaliza correos con mayúsculas al buscar" do
      auth = build_auth(email: "TEST-OAUTH@GMAIL.COM", uid: "uid-normalized")

      result = User.find_and_update_from_google(auth)

      expect(result).to eq(user)
      expect(user.reload.google_uid).to eq("uid-normalized")
    end

    it "soporta imágenes nulas sin fallar la persistencia" do
      auth = build_auth(email: user.email, uid: "uid-no-avatar", image: nil)

      result = User.find_and_update_from_google(auth)

      expect(result).to eq(user)
      expect(user.reload.avatar_url).to be_nil
      expect(user.google_uid).to eq("uid-no-avatar")
    end
  end

  describe "reseteo de google_uid al cambiar email" do
    let(:user) { users(:one) }

    before do
      user.update!(google_uid: "saved-uid-123", verified: true)
    end

    it "resetea google_uid a nil y verified a false cuando se modifica el email" do
      expect {
        user.update!(email: "newemail@gmail.com")
      }.to change(user, :google_uid).from("saved-uid-123").to(nil)
        .and change(user, :verified).from(true).to(false)
    end

    it "mantiene google_uid y verified si solo se actualizan otros atributos" do
      expect {
        user.update!(name: "Nombre Actualizado", phone: "+59899123456")
      }.not_to change(user, :google_uid)
      expect(user.reload.verified).to be(true)
    end
  end

  describe "validación de unicidad de google_uid" do
    it "no permite que dos usuarios tengan el mismo google_uid" do
      users(:one).update!(google_uid: "shared-uid-999")
      duplicate = User.new(
        name: "Clon",
        email: "clon@gmail.com",
        password: "Secret1*3*5*123",
        google_uid: "shared-uid-999"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:google_uid]).to be_present
    end

    it "permite múltiples usuarios con google_uid nil" do
      users(:one).update!(google_uid: nil)
      users(:two).update!(google_uid: nil)

      expect(users(:one)).to be_valid
      expect(users(:two)).to be_valid
    end
  end

  describe "#roles" do
    it "calcula dinámicamente los roles según la existencia en cada modelo" do
      user = users(:two)
      expect(user.roles).to eq([])

      expect(users(:one).roles).to eq([ "consumer" ])
      expect(users(:admin).roles).to eq([ "admin" ])
      expect(users(:provider_user).roles).to eq([ "provider" ])

      Admin.create!(user: users(:one), company: companies(:gogrow))
      expect(users(:one).roles).to match_array([ "consumer", "admin" ])
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
#  phone           :string
#  verified        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#
