# frozen_string_literal: true

class Company < ApplicationRecord
  has_many :admins
  has_many :consumers
  has_many :accounts, as: :owner
end

# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  address    :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
