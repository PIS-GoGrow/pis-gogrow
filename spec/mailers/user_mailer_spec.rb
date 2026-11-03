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
      expect(mail.subject).to eq("Verificá tu correo electrónico")
    end
  end

  describe "invitation" do
    let(:user) { Providers::Invite.call(name: "Ana Proveedora", email: "ana@proveedor.com", company: companies(:gogrow)) }
    let(:otp_code) { OtpCode.find_by!(user: user, purpose: :invitation) }
    let(:mail) { described_class.with(otp_code: otp_code, company: companies(:gogrow)).invitation }

    it "is sent to the invited provider with the right subject" do
      expect(mail.to).to eq([ "ana@proveedor.com" ])
      expect(mail.subject).to eq("Fuiste invitado a Viandas GoGrow")
    end

    it "greets by name, names the company and links to the registration" do
      body = mail.html_part.body.decoded

      expect(body).to include("Hola Ana Proveedora,")
      expect(body).to include("GoGrow te invitó a unirte como proveedor de viandas")
      expect(body).to include("/proveedor/bienvenida?company=")
      expect(body).to include("token=#{user.id}.#{otp_code.code}")
      expect(body).to include("Unirme ahora")
      expect(body).to include("/proveedor")
    end

    it "is sent as Viandas with the brand images attached inline" do
      expect(mail[:from].display_names).to eq([ "Viandas" ])
      expect(mail.attachments.map(&:filename)).to contain_exactly("logo-mark.png", "gogrow-wordmark.png")
      expect(mail.attachments).to all(be_inline)
      expect(mail.html_part.body.decoded).to include("cid:")
    end

    it "renders the branded layout with proper title, container and image alt attributes" do
      body = mail.html_part.body.decoded

      expect(body).to include("<title>Fuiste invitado a Viandas GoGrow</title>")
      expect(body).to include("Fuiste invitado a Viandas GoGrow</h1>")
      expect(body).to include("max-width: 480px")
      expect(body).to include('alt="Viandas GoGrow"')
      expect(body).to include('alt="GoGrow"')
    end

    it "renders gracefully without crashing when brand images are not attached" do
      allow_any_instance_of(described_class).to receive(:attach_brand_images)
      unbranded_mail = described_class.with(otp_code: otp_code, company: companies(:gogrow)).invitation
      body = (unbranded_mail.html_part || unbranded_mail).body.decoded

      expect(body).to include("Fuiste invitado a Viandas GoGrow</h1>")
    end

    context "when company or provider name contains special HTML characters" do
      let(:user) { Providers::Invite.call(name: "Ana & Cía <Test>", email: "ana_special@proveedor.com", company: companies(:gogrow)) }

      it "escapes HTML entities in the body" do
        body = mail.html_part.body.decoded

        expect(body).to include("Ana &amp; Cía &lt;Test&gt;")
      end
    end

    context "when custom SMTP_FROM is configured" do
      it "uses configured email address while keeping Viandas sender name" do
        stub_const("ENV", ENV.to_hash.merge("SMTP_FROM" => "notificaciones@gogrow.com"))
        custom_mail = described_class.with(otp_code: otp_code, company: companies(:gogrow)).invitation

        expect(custom_mail.from).to eq([ "notificaciones@gogrow.com" ])
        expect(custom_mail[:from].display_names).to eq([ "Viandas" ])
      end
    end
  end

  describe "password_reset_code" do
    let(:otp_code) { OtpCode.issue(users(:provider_user), :password_reset) }
    let(:mail) { described_class.with(otp_code: otp_code).password_reset_code }

    it "is sent to the provider with the right subject" do
      expect(mail.to).to eq([ "provider@example.com" ])
      expect(mail.subject).to eq("Restablecimiento de contraseña")
    end

    it "shows the six digit code, exact copy from Figma and how long it lasts" do
      body = mail.html_part.body.decoded

      expect(body).to include("<title>Restablecimiento de Contraseña</title>")
      expect(body).to include("Restablecimiento de Contraseña</h1>")
      expect(body).to include("Hola #{users(:provider_user).name},")
      expect(body).to include("Si fuiste vos, ingresá el siguiente código para crear una nueva contraseña:")
      expect(body).to include(otp_code.code)
      expect(body).to include("text-align: left;")
      expect(body).to include("Este código es válido por los próximos 20 minutos. Si no solicitaste un restablecimiento de contraseña, contactá a nuestro equipo de soporte.")
      expect(body).to include(companies(:gogrow).name)
    end

    it "is sent as Viandas with the brand images attached inline" do
      expect(mail[:from].display_names).to eq([ "Viandas" ])
      expect(mail.attachments.map(&:filename)).to contain_exactly("logo-mark.png", "gogrow-wordmark.png")
      expect(mail.attachments).to all(be_inline)
      expect(mail.html_part.body.decoded).to include("cid:")
    end
  end
end
