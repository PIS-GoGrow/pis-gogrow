# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
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
#  roles           :string           default([]), not null, is an Array
#  verified        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#
