# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  fixtures :users

  describe "email_verification" do
    let(:mail) { described_class.with(user: users(:one)).email_verification }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "one@example.com" ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Verifica tu correo electrónico")
    end
  end

  describe "invitation" do
    let(:user) { Providers::Invite.call(name: "Ana Proveedora", email: "ana@proveedor.com", company: companies(:gogrow)) }
    let(:otp_code) { OtpCode.find_by!(user: user, purpose: :invitation) }
    let(:mail) { described_class.with(otp_code: otp_code, company: companies(:gogrow)).invitation }

    it "is sent to the invited provider with the right subject" do
      expect(mail.to).to eq([ "ana@proveedor.com" ])
      expect(mail.subject).to eq("Invitación a Viandas GoGrow")
    end

    it "greets by name, names the company and links to the registration" do
      body = mail.body.encoded

      expect(body).to include("Hola Ana Proveedora,")
      expect(body).to include("Recibió una invitación de GoGrow para unirse como proveedor de viandas")
      expect(body).to include("/provider/invitation?token=#{user.id}.#{otp_code.code}")
      expect(body).to include("/provider")
    end
  end

  describe "password_reset_code" do
    let(:otp_code) { OtpCode.issue(users(:provider_user), :password_reset) }
    let(:mail) { described_class.with(otp_code: otp_code).password_reset_code }

    it "is sent to the provider with the right subject" do
      expect(mail.to).to eq([ "provider@example.com" ])
      expect(mail.subject).to eq("Restablecimiento de contraseña")
    end

    it "shows the six digit code and how long it lasts" do
      body = mail.body.encoded

      expect(body).to include(otp_code.code)
      expect(body).to include("20 minutos")
    end
  end
end
