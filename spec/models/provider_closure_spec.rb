# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderClosure, type: :model do
  fixtures :users, :providers

  let(:provider) { providers(:tuviandita) }
  let(:today) { Date.new(2026, 10, 12) }

  before { travel_to Time.zone.local(2026, 10, 12, 9, 0) }

  def closure(provider: self.provider, **attributes)
    described_class.new(provider:, starts_on: today + 1, ends_on: today + 3, reason: "Vacaciones", **attributes)
  end

  def message(key, attribute: :base)
    I18n.t("activerecord.errors.models.provider_closure.attributes.#{attribute}.#{key}")
  end

  it "is valid with a range and a reason" do
    expect(closure).to be_valid
  end

  it "accepts a single day" do
    expect(closure(starts_on: today + 2, ends_on: today + 2)).to be_valid
  end

  it "accepts a closure that starts today" do
    expect(closure(starts_on: today)).to be_valid
  end

  describe "reason" do
    it "is required" do
      [ nil, "", "   " ].each do |blank|
        record = closure(reason: blank)

        expect(record).not_to be_valid
        expect(record.errors[:reason]).to eq([ message(:blank, attribute: :reason) ])
      end
    end

    it "accepts up to 100 characters and rejects more" do
      expect(closure(reason: "a" * 100)).to be_valid
      expect(closure(reason: "a" * 101)).not_to be_valid
    end
  end

  describe "dates" do
    it "requires both" do
      record = closure(starts_on: nil, ends_on: nil)

      expect(record).not_to be_valid
      expect(record.errors[:starts_on]).to eq([ message(:blank, attribute: :starts_on) ])
      expect(record.errors[:ends_on]).to eq([ message(:blank, attribute: :ends_on) ])
    end

    it "rejects an end before the start" do
      record = closure(starts_on: today + 3, ends_on: today + 2)

      expect(record).not_to be_valid
      expect(record.errors[:ends_on]).to eq([ message(:greater_than_or_equal_to, attribute: :ends_on) ])
    end

    it "rejects a start in the past" do
      record = closure(starts_on: today - 1, ends_on: today + 1)

      expect(record).not_to be_valid
      expect(record.errors[:starts_on]).to eq([ message(:greater_than_or_equal_to, attribute: :starts_on) ])
    end

    it "lets a closure already in progress be shortened or extended" do
      record = closure(starts_on: today, ends_on: today + 2).tap(&:save!)

      travel_to Time.zone.local(2026, 10, 13, 9, 0)

      expect(record.reload.update(ends_on: today + 5)).to be true
      expect(record.update(ends_on: today + 1)).to be true
    end

    it "rejects moving the start of a closure to the past" do
      record = closure.tap(&:save!)

      expect(record.update(starts_on: today - 1)).to be false
    end

    it "is enforced by the database too" do
      record = closure.tap(&:save!)

      expect { record.update_columns(ends_on: record.starts_on - 1) }.to raise_error(ActiveRecord::CheckViolation)
    end
  end

  describe "overlaps" do
    before { closure(starts_on: today + 5, ends_on: today + 9).save! }

    {
      "the same range" => [ 5, 9 ],
      "a range inside it" => [ 6, 7 ],
      "a range around it" => [ 4, 10 ],
      "a range that overlaps its start" => [ 3, 5 ],
      "a range that overlaps its end" => [ 9, 11 ],
      "the same single day at its start" => [ 5, 5 ]
    }.each do |description, (from, to)|
      it "rejects #{description} for the same provider" do
        record = closure(starts_on: today + from, ends_on: today + to)

        expect(record).not_to be_valid
        expect(record.errors[:base]).to eq([ message(:overlaps) ])
      end
    end

    it "accepts contiguous ranges" do
      expect(closure(starts_on: today + 2, ends_on: today + 4)).to be_valid
      expect(closure(starts_on: today + 10, ends_on: today + 12)).to be_valid
    end

    it "accepts the same range for another provider" do
      expect(closure(provider: providers(:endulzate), starts_on: today + 5, ends_on: today + 9)).to be_valid
    end

    it "does not overlap with itself when edited" do
      record = provider.closures.find_by!(starts_on: today + 5)

      expect(record.update(ends_on: today + 8)).to be true
    end

    it "rejects editing a closure into another one" do
      other = closure(starts_on: today + 11, ends_on: today + 12).tap(&:save!)

      expect(other.update(starts_on: today + 9)).to be false
      expect(other.errors[:base]).to eq([ message(:overlaps) ])
    end
  end

  describe "#covers?" do
    let(:record) { closure(starts_on: today + 2, ends_on: today + 4) }

    it "includes both ends" do
      expect(record.covers?(today + 2)).to be true
      expect(record.covers?(today + 3)).to be true
      expect(record.covers?(today + 4)).to be true
    end

    it "excludes the days around" do
      expect(record.covers?(today + 1)).to be false
      expect(record.covers?(today + 5)).to be false
    end
  end

  describe ".upcoming" do
    it "lists closures that have not ended, soonest first" do
      later = closure(starts_on: today + 20, ends_on: today + 22).tap(&:save!)
      sooner = closure(starts_on: today + 1, ends_on: today + 2).tap(&:save!)
      ended = closure(starts_on: today, ends_on: today).tap(&:save!)

      travel_to Time.zone.local(2026, 10, 13, 9, 0)

      expect(provider.closures.upcoming).to eq([ sooner, later ])
      expect(provider.closures.upcoming).not_to include(ended)
    end

    it "keeps a closure on its last day" do
      record = closure(starts_on: today, ends_on: today + 1).tap(&:save!)

      travel_to Time.zone.local(2026, 10, 13, 9, 0)

      expect(provider.closures.upcoming).to include(record)
    end
  end

  it "is destroyed with its provider" do
    record = closure.tap(&:save!)

    expect { provider.destroy! }.to change { described_class.exists?(record.id) }.from(true).to(false)
  end

  describe "database integrity and boundary cases" do
    it "raises NotNullViolation when starts_on is nil at database level" do
      record = closure.tap(&:save!)
      expect { record.update_column(:starts_on, nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "raises NotNullViolation when ends_on is nil at database level" do
      record = closure.tap(&:save!)
      expect { record.update_column(:ends_on, nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "raises NotNullViolation when reason is nil at database level" do
      record = closure.tap(&:save!)
      expect { record.update_column(:reason, nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "raises NotNullViolation when provider_id is nil at database level" do
      record = closure.tap(&:save!)
      expect { record.update_column(:provider_id, nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "handles ranges crossing the year boundary" do
      new_year_closure = closure(starts_on: Date.new(2026, 12, 30), ends_on: Date.new(2027, 1, 3))
      expect(new_year_closure).to be_valid
      expect(new_year_closure.covers?(Date.new(2026, 12, 31))).to be true
      expect(new_year_closure.covers?(Date.new(2027, 1, 1))).to be true
      expect(new_year_closure.covers?(Date.new(2027, 1, 4))).to be false
    end
  end
end

# == Schema Information
#
# Table name: provider_closures
#
#  id          :bigint           not null, primary key
#  ends_on     :date             not null
#  reason      :string           not null
#  starts_on   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_provider_closures_on_provider_id                (provider_id)
#  index_provider_closures_on_provider_id_and_starts_on  (provider_id,starts_on)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
