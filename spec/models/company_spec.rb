# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: companies
#
#  id                   :bigint           not null, primary key
#  address              :string
#  debt_alert_threshold :integer          default(2000), not null
#  name                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
