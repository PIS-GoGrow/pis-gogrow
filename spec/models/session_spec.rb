# frozen_string_literal: true

require "rails_helper"

RSpec.describe Session, type: :model do
  fixtures :users, :consumers, :providers, :admins, :companies

  describe "constants" do
    it "defines ENTRY_ROLES for entry paths" do
      expect(Session::ENTRY_ROLES).to eq(
        "/consumidor" => "consumer",
        "/rrhh" => "admin",
        "/proveedor" => "provider"
      )
    end
  end

  describe "associations and validations" do
    it "belongs to a user" do
      session = users(:one).sessions.build(role: :consumer)
      expect(session.user).to eq(users(:one))
      expect(session).to be_valid
    end

    it "requires a user" do
      session = Session.new(role: :consumer)
      expect(session).not_to be_valid
      expect(session.errors[:user]).to be_present
    end

    it "supports consumer, provider and admin roles according to user profiles" do
      expect(users(:one).sessions.create!(role: :consumer)).to be_consumer
      expect(users(:provider_user).sessions.create!(role: :provider)).to be_provider
      expect(users(:admin).sessions.create!(role: :admin)).to be_admin
    end

    it "rejects a role the user does not possess" do
      expect {
        users(:one).sessions.create!(role: :admin)
      }.to raise_error(ActiveRecord::RecordInvalid, /Role no está disponible/)
    end
  end
end
