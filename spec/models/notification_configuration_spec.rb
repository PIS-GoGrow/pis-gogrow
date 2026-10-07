# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationConfiguration, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id          :bigint           not null, primary key
#  description :string
#  key         :string           not null
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
