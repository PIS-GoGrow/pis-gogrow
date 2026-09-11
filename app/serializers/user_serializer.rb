# frozen_string_literal: true

class UserSerializer < ApplicationSerializer
  attributes :id, :name, :email, :verified, :created_at, :updated_at

  typelize :string?
  attribute :avatar do |user|
    user.avatar_url
  end

  typelize :string
  attribute :role do |user|
    user.role
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
#  verified        :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email       (email) UNIQUE
#  index_users_on_google_uid  (google_uid) UNIQUE
#
