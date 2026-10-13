# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Internal provider invitations", type: :request do
  let(:company) { companies(:gogrow) }
  let(:token) { "token-de-prueba" }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:params) { { name: "Ana Proveedora", email: "ana@proveedor.com", company_id: company.id } }

  around do |example|
    original = ENV["MOTOR_ADMIN_API_TOKEN"]
    ENV["MOTOR_ADMIN_API_TOKEN"] = token
    example.run
  ensure
    ENV["MOTOR_ADMIN_API_TOKEN"] = original
  end

  it "creates the provider and sends the invitation" do
    expect {
      post internal_provider_invitations_path, params: params, headers: headers
    }.to have_enqueued_mail(UserMailer, :invitation).and change(Provider, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(User.find_by!(email: "ana@proveedor.com")).not_to be_verified
  end

  it "rejects a missing token" do
    post internal_provider_invitations_path, params: params

    expect(response).to have_http_status(:unauthorized)
    expect(User.find_by(email: "ana@proveedor.com")).to be_nil
  end

  it "rejects a wrong token" do
    post internal_provider_invitations_path, params: params, headers: { "Authorization" => "Bearer otro" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "answers 404 when no token is configured" do
    ENV["MOTOR_ADMIN_API_TOKEN"] = nil

    post internal_provider_invitations_path, params: params, headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it "rejects an email that already has an account" do
    post internal_provider_invitations_path, params: params.merge(email: users(:consumer_user).email), headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to include("errors" => [ "Ya existe un usuario con ese correo" ], "message" => "Ya existe un usuario con ese correo")
  end

  it "re-invites a provider who has not accepted yet" do
    post internal_provider_invitations_path, params: params, headers: headers
    OtpCode.update_all(sent_at: 1.hour.ago)

    expect {
      post internal_provider_invitations_path, params: params, headers: headers
    }.to have_enqueued_mail(UserMailer, :invitation)
    expect(response).to have_http_status(:created)
  end

  it "answers 404 for an unknown company" do
    post internal_provider_invitations_path, params: params.merge(company_id: 0), headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it "falls back to the first company when company_id is omitted" do
    expect {
      post internal_provider_invitations_path, params: params.except(:company_id), headers: headers
    }.to have_enqueued_mail(UserMailer, :invitation).with(
      a_hash_including(params: a_hash_including(company: Company.first))
    )

    expect(response).to have_http_status(:created)
  end

  it "answers 422 when a parameter is missing" do
    post internal_provider_invitations_path, params: params.except(:name), headers: headers

    expect(response).to have_http_status(:unprocessable_content)
  end
end
