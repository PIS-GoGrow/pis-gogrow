# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :user

  enum :role, { provider: 0, admin: 1, consumer: 2 }

  before_create do
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string
#  role       :integer          not null
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
