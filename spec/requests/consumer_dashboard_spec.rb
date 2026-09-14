# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer dashboard", type: :request do
  def consumer_user
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    user = User.create!(email: "consumer-menu@gmail.com", name: "Sofía", password: "password123456")
    Consumer.create!(user:, company:, address: "Ellauri 1234")
    user
  end

  def sign_in_as_consumer(user)
    session = user.sessions.create!(role: :consumer)
    cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
  end

  def create_schedule
    provider_user = User.create!(email: "provider-menu@gmail.com", name: "Endulzate by Noe", password: "password123456")
    provider = Provider.create!(user: provider_user)
    menu = Menu.create!(provider:, name: "Sorrentinos", description: "Jamón y queso", price: 300)
    Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount: 5)
  end

  it "uses the weekly menu as the landing page for a remembered consumer session" do
    user = consumer_user
    sign_in_as_consumer(user)

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end

  it "renders the protected weekly menu with its server props" do
    user = consumer_user
    schedule = create_schedule
    Benefit.create!(consumer: user.consumer, amount: 5, percentage: 50, due_date: 1.month.from_now)
    sign_in_as_consumer(user)

    get dashboard_path

    expect(response).to have_http_status(:success)
    expect(inertia).to render_component("consumer/dashboard/index")
    expect(inertia).to have_props { |props|
      props[:schedules].one? &&
        props[:schedules].first[:id] == schedule.id &&
        props.dig(:benefit, :percentage) == 50 &&
        props[:addresses].pluck(:label) == [ "Oficina", "Casa" ]
    }
  end

  it "rejects a session with a different role" do
    user = consumer_user
    session = user.sessions.create!(role: :provider)
    cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

    get dashboard_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "selects the consumer role from the Google sign-in cookie" do
    user = consumer_user
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "consumer-menu-google-uid",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: user.email,
        name: user.name,
        image: "https://example.com/avatar.png"
      )
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    cookies[:accessing_role] = AuthenticationHelpers.signed_cookie(:accessing_role, "consumer")

    get "/auth/google_oauth2/callback"

    expect(response).to redirect_to(root_path)
    expect(user.sessions.last).to be_consumer
    expect(cookies[:session_token]).to be_present
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
