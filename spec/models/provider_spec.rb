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
#  order_deadline :time
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
