# frozen_string_literal: true

class Consumer < ApplicationRecord
  belongs_to :company

  has_many :orders
  has_many :benefits
  has_many :accounts, as: :owner
  has_many :user_notifications, as: :user
  has_many :notification_configurations, through: :user_notifications, source: :notification_configuration
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
