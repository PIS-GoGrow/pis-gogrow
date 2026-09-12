# frozen_string_literal: true

class SessionSerializer < ApplicationSerializer
  attributes :id, :user_agent, :ip_address, :created_at

  typelize :string
  attribute :role do |session|
    session.role
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
