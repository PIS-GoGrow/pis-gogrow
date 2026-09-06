# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :menus
end

# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  email          :string
#  order_deadline :time
#  username       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_providers_on_email  (email) UNIQUE
#
