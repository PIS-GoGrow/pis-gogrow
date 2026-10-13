# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  fixtures :users

  describe "/sign_up" do
    it "does not exist" do
      get "/sign_up"
      expect(response).to have_http_status(:not_found)
    end

    it "does not create users" do
      expect {
        post "/sign_up", params: {
          name: "New User",
          email: "new@example.com",
          password: "Secret1*3*5*",
          password_confirmation: "Secret1*3*5*"
        }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /users" do
    it "requires authentication" do
      delete users_path, params: { password_challenge: "Secret1*3*5*" }
      expect(response).to redirect_to(sign_in_path)
    end

    it "destroys current user with valid password" do
      sign_in users(:one)
      expect {
        delete users_path, params: { password_challenge: "Secret1*3*5*" }
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(root_path)
    end

    it "rejects account deletion with wrong password" do
      sign_in users(:one)
      expect {
        delete users_path, params: { password_challenge: "wrongpassword" }
      }.not_to change(User, :count)
      expect(response).to redirect_to(settings_profile_path)
    end

    it "rejects account deletion when password_challenge is empty or nil" do
      sign_in users(:one)
      expect {
        delete users_path, params: {}
      }.not_to change(User, :count)
      expect(response).to redirect_to(settings_profile_path)
    end

    it "handles unexpected parameter types gracefully" do
      sign_in users(:one)
      expect {
        delete users_path, params: { password_challenge: [ 12345 ] }
      }.not_to change(User, :count)
      expect(response).to redirect_to(settings_profile_path)
    end
  end
end
