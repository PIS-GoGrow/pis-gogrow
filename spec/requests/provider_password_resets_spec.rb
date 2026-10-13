# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Provider password reset", type: :request do
  let(:provider) { users(:provider_user) }
  let(:strong_password) { "Nueva-Clave-2026-ok!" }

  def request_code(email = provider.email)
    post provider_password_reset_path, params: { email: email }
  end

  def current_code
    OtpCode.find_by!(user: provider, purpose: :password_reset).code
  end

  def verify_code(code)
    post provider_password_reset_code_path, params: { code: code }
  end

  def change_password(password: strong_password, confirmation: strong_password)
    patch provider_password_reset_path, params: { password: password, password_confirmation: confirmation }
  end

  describe "POST /provider/password" do
    it "sends a code to a provider and moves to the code screen" do
      expect { request_code }.to have_enqueued_email(UserMailer, :password_reset_code)

      expect(response).to redirect_to(provider_password_reset_code_path)
      expect(OtpCode.where(user: provider, purpose: :password_reset).count).to eq(1)
    end

    it "does not send anything to an unknown email but answers the same" do
      expect { request_code("nadie@example.com") }.not_to have_enqueued_mail(UserMailer, :password_reset_code)

      expect(response).to redirect_to(provider_password_reset_code_path)
    end

    it "does not send anything to an account that is not a provider" do
      expect { request_code(users(:one).email) }.not_to have_enqueued_mail(UserMailer, :password_reset_code)

      expect(response).to redirect_to(provider_password_reset_code_path)
    end

    it "rejects an invalid email" do
      post provider_password_reset_path, params: { email: "no-es-un-mail" }

      expect(response).to redirect_to(provider_sign_in_path)
      follow_redirect!
      expect(inertia.props[:errors]).to include(email: [ I18n.t("validations.invalid_email") ])
    end

    it "does not send a second code during the cooldown" do
      request_code

      expect { request_code }.not_to have_enqueued_mail(UserMailer, :password_reset_code)
    end

    it "limits the requests per email" do
      5.times { |i| travel(i * 6.minutes) { request_code } }

      travel 5 * 6.minutes do
        expect { request_code }.not_to have_enqueued_mail(UserMailer, :password_reset_code)
        expect(flash[:alert]).to eq(I18n.t("flash.too_many_attempts"))
      end
    end
  end

  describe "GET /provider/password/code" do
    it "sends the visitor back to sign in when no code was requested" do
      get provider_password_reset_code_path

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "shows the email and the seconds left before a resend" do
      request_code
      get provider_password_reset_code_path

      expect(inertia).to render_component("provider_password_reset_codes/show")
      expect(inertia).to have_props(email: provider.email)
      expect(inertia.props[:resend_in]).to be_between(295, 300)
    end

    it "shows the same screen for an unknown email" do
      request_code("nadie@example.com")
      get provider_password_reset_code_path

      expect(inertia).to have_props(email: "nadie@example.com")
      expect(inertia.props[:resend_in]).to be_between(295, 300)
    end

    it "counts the resend time down" do
      request_code

      travel(2.minutes) do
        get provider_password_reset_code_path
        expect(inertia.props[:resend_in]).to be_between(175, 180)
      end
    end
  end

  describe "POST /provider/password/code" do
    before { request_code }

    it "accepts the right code and opens the new password screen" do
      verify_code(current_code)

      expect(response).to redirect_to(edit_provider_password_reset_path)
      follow_redirect!
      expect(inertia).to render_component("provider_password_resets/edit")
      expect(inertia).to have_props(email: provider.email)
    end

    it "rejects a wrong code and keeps the user on the code screen" do
      verify_code(current_code == "000000" ? "000001" : "000000")

      expect(response).to redirect_to(provider_password_reset_code_path)
      follow_redirect!
      expect(inertia.props[:errors]).to include(code: [ I18n.t("validations.invalid_code") ])
    end

    it "does not let a code be used twice" do
      code = current_code
      verify_code(code)
      reset!
      request_code
      verify_code(code)

      expect(response).to redirect_to(provider_password_reset_code_path)
    end

    it "rejects an expired code" do
      code = current_code

      travel(21.minutes) { verify_code(code) }

      expect(response).to redirect_to(provider_password_reset_code_path)
    end

    it "locks the code after five wrong attempts" do
      code = current_code
      5.times { verify_code(code == "000000" ? "000001" : "000000") }

      verify_code(code)

      expect(response).to redirect_to(provider_password_reset_code_path)
    end

    it "fails the same way for an unknown email" do
      reset!
      request_code("nadie@example.com")
      verify_code("123456")

      expect(response).to redirect_to(provider_password_reset_code_path)
      follow_redirect!
      expect(inertia.props[:errors]).to include(code: [ I18n.t("validations.invalid_code") ])
    end

    it "does not accept the code of another provider" do
      other = users(:other_provider_user)
      other_code = OtpCode.issue(other, :password_reset).code

      verify_code(other_code)

      expect(response).to redirect_to(provider_password_reset_code_path)
    end
  end

  describe "the new password screen" do
    it "is closed without a verified code" do
      get edit_provider_password_reset_path

      expect(response).to redirect_to(provider_sign_in_path)
      expect(flash[:alert]).to eq(I18n.t("flash.password_reset_expired"))
    end

    it "is closed when the authorization expired" do
      request_code
      verify_code(current_code)

      travel(16.minutes) { get edit_provider_password_reset_path }

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "cannot be used to change the password without a verified code" do
      change_password

      expect(response).to redirect_to(provider_sign_in_path)
      expect(provider.reload.authenticate(strong_password)).to be(false)
    end
  end

  describe "PATCH /provider/password" do
    before do
      request_code
      verify_code(current_code)
    end

    it "sets the new password, signs out every other session and consumes the code" do
      old_session = provider.sessions.create!(role: :provider)

      change_password

      expect(provider.reload.authenticate(strong_password)).to be_truthy
      expect(Session.exists?(old_session.id)).to be(false)
      expect(OtpCode.pending?(provider, :password_reset)).to be(false)
    end

    it "signs the provider in and sends them to the dashboard" do
      change_password

      expect(response).to redirect_to(provider_dashboard_path)
      expect(provider.sessions.pluck(:role)).to eq([ "provider" ])

      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "does not work twice with the same authorization" do
      change_password
      change_password(password: "Otra-Clave-2026-ok!!", confirmation: "Otra-Clave-2026-ok!!")

      expect(provider.reload.authenticate(strong_password)).to be_truthy
    end

    {
      "too short" => "Aa1!aaaa",
      "without an uppercase letter" => "nueva-clave-2026-ok!",
      "without a number" => "Nueva-Clave-Segura-ok!",
      "without a special character" => "NuevaClave2026okayy"
    }.each do |reason, weak|
      it "rejects a password #{reason}" do
        change_password(password: weak, confirmation: weak)

        expect(response).to redirect_to(edit_provider_password_reset_path)
        follow_redirect!
        expect(inertia.props[:errors][:password]).to be_present
        expect(provider.reload.authenticate(weak)).to be(false)
      end
    end

    it "rejects a confirmation that does not match" do
      change_password(confirmation: "Distinta-Clave-2026!!")

      follow_redirect!
      expect(inertia.props[:errors][:password_confirmation]).to be_present
      expect(provider.reload.authenticate(strong_password)).to be(false)
    end

    it "rejects a blank password" do
      change_password(password: "", confirmation: "")

      follow_redirect!
      expect(inertia.props[:errors][:password]).to be_present
    end
  end

  describe "a provider that was invited but never finished the registration" do
    it "can recover the account with a code and ends up verified" do
      provider.update!(verified: false)

      request_code
      verify_code(current_code)
      change_password

      expect(provider.reload).to be_verified
    end
  end
end
