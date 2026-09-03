# frozen_string_literal: true

class Admin < ApplicationRecord
  belongs_to :company
end

# == Schema Information
#
# Table name: admins
#
#  id         :bigint           not null, primary key
#  email      :string
#  username   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_admins_on_company_id  (company_id)
#  index_admins_on_email       (email) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
