# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: reviews
#
#  id          :bigint           not null, primary key
#  description :string
#  rating      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  menu_id     :bigint           not null
#
# Indexes
#
#  index_reviews_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
