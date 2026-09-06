# frozen_string_literal: true

require "rails_helper"

RSpec.describe Benefit, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: benefits
#
#  id          :bigint           not null, primary key
#  amount      :integer
#  description :string
#  due_date    :date
#  percentage  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint           not null
#
# Indexes
#
#  index_benefits_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
