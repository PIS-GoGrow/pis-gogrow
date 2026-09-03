# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
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
