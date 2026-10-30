# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  fixtures :users

  describe "GET /iniciar-sesion" do
    it "redirects to the consumer sign in" do
      get "/iniciar-sesion"

      expect(response).to redirect_to("/consumidor")
    end
  end

  describe "POST /iniciar-sesion" do
    context "with valid credentials" do
      it "signs in and sets a session cookie" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(root_path)
        expect(cookies[:session_token]).to be_present

        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid credentials" do
      it "redirects back with an alert" do
        post sign_in_path, params: { email: users(:one).email, password: "wrongpassword" }
        expect(response).to redirect_to(consumer_welcome_path)
        expect(flash[:alert]).to eq("El correo electrónico o la contraseña son incorrectos")

        get dashboard_path
        expect(response).to redirect_to(consumer_welcome_path)
      end

      it "handles blank or missing parameters gracefully" do
        post sign_in_path, params: { email: "", password: "" }
        expect(response).to redirect_to(consumer_welcome_path)
        expect(flash[:alert]).to eq("El correo electrónico o la contraseña son incorrectos")
        expect(Session.count).to eq(0)
      end
    end

    context "with a consumer and HR account" do
      before do
        Admin.create!(user: users(:one), company: Company.first || Company.create!(name: "GoGrow", address: "18 de Julio 1006"))
        users(:one).sync_roles!
      end

      it "opens the session with the role of the screen it came from" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }, headers: { "Referer" => "http://www.example.com/rrhh" }

        expect(users(:one).sessions.last).to be_admin
      end

      it "opens the consumer session when coming from /consumidor" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }, headers: { "Referer" => "http://www.example.com/consumidor" }

        expect(users(:one).sessions.last).to be_consumer
      end

      it "falls back to user's first role when referer is unknown" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }, headers: { "Referer" => "http://www.example.com/desconocido" }

        expect(response).to redirect_to(root_path)
        expect(users(:one).sessions.last.role).to eq(users(:one).roles.first)
      end

      it "sends a failed login back to the screen it came from" do
        post sign_in_path, params: { email: users(:one).email, password: "mala" }, headers: { "Referer" => "http://www.example.com/rrhh" }

        expect(response).to redirect_to("/rrhh")
      end
    end

    context "with an admin-only account" do
      it "rejects the login from /consumidor" do
        post sign_in_path, params: { email: users(:admin).email, password: "Secret1*3*5*" }, headers: { "Referer" => "http://www.example.com/consumidor" }

        expect(response).to redirect_to(consumer_welcome_path)
        expect(flash[:alert]).to eq(I18n.t("flash.role_not_available"))
        expect(users(:admin).sessions).to be_empty
      end
    end

    context "with a consumer-only account" do
      it "rejects the login from /rrhh via Referer" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*" }, headers: { "Referer" => "http://www.example.com/rrhh" }

        expect(response).to redirect_to("/rrhh")
        expect(users(:one).sessions).to be_empty
      end

      it "rejects the login from /rrhh via origin param" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*", origin: "/rrhh" }

        expect(response).to redirect_to("/rrhh")
        expect(flash[:alert]).to eq(I18n.t("flash.role_not_available"))
        expect(users(:one).sessions).to be_empty
      end

      it "rejects the login from /proveedor via origin param" do
        post sign_in_path, params: { email: users(:one).email, password: "Secret1*3*5*", origin: "/proveedor" }

        expect(response).to redirect_to("/proveedor")
        expect(flash[:alert]).to eq(I18n.t("flash.role_not_available"))
        expect(users(:one).sessions).to be_empty
      end
    end

    context "with a provider account" do
      it "opens the session with the provider role" do
        post sign_in_path, params: { email: users(:provider_user).email, password: "Secret1*3*5*" }

        expect(response).to redirect_to(root_path)
        expect(users(:provider_user).sessions.last.role).to eq("provider")
      end
    end

    context "with an HR account" do
      it "opens the session with the admin role" do
        post sign_in_path, params: { email: users(:admin).email, password: "Secret1*3*5*" }

        expect(response).to redirect_to(root_path)
        expect(users(:admin).sessions.last.role).to eq("admin")
      end
    end

    context "when user has no profile" do
      it "denies access and redirects to sign in" do
        post sign_in_path, params: { email: users(:two).email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(consumer_welcome_path)
        expect(flash[:alert]).to eq(I18n.t("flash.role_not_available"))
      end
    end
  end

  describe "DELETE /sesiones/:id" do
    it "destroys the session" do
      sign_in users(:one)
      session_record = users(:one).sessions.last
      delete session_path(session_record)
      expect(response).to redirect_to(root_path)
      expect(Session.exists?(session_record.id)).to be(false)
    end

    it "sends a provider back to the provider sign in" do
      sign_in users(:provider_user), role: :provider
      delete session_path(users(:provider_user).sessions.last)

      expect(response).to redirect_to(provider_sign_in_path)
    end
  end
end
