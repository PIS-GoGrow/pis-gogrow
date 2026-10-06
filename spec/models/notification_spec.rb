# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: notifications
#
#  id              :bigint           not null, primary key
#  closed          :boolean
#  description     :string
#  requires_action :boolean
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_notifications_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
