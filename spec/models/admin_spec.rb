# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin, type: :model do
  fixtures :users, :companies

  let(:company) { companies(:gogrow) }
  let(:user) { users(:one) }

  describe "associations" do
    it "belongs to a company and a user" do
      admin = described_class.new(company:, user:)
      expect(admin.company).to eq(company)
      expect(admin.user).to eq(user)
    end

    it "is invalid without a company" do
      admin = described_class.new(company: nil, user:)
      expect(admin).not_to be_valid
    end

    it "is invalid without a user" do
      admin = described_class.new(company:, user: nil)
      expect(admin).not_to be_valid
    end
  end

  describe "role synchronization" do
    it "syncs the admin role into the user upon creation" do
      new_user = User.create!(name: "RRHH Admin", email: "rrhh@gogrow.com", password: "password123456")
      described_class.create!(company:, user: new_user)

      expect(new_user.reload.roles).to include("admin")
    end
  end
end

# == Schema Information
#
# Table name: admins
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_admins_on_company_id  (company_id)
#  index_admins_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
