# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consumer, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: consumers
#
#  id         :bigint           not null, primary key
#  address    :string
#  email      :string
#  username   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_consumers_on_company_id  (company_id)
#  index_consumers_on_email       (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
