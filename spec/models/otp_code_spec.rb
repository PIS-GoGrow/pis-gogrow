# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtpCode, type: :model do
  let(:user) { users(:one) }

  describe ".issue" do
    it "creates a code that expires according to its purpose" do
      otp = described_class.issue(user, :password_reset)

      expect(otp).to be_persisted
      expect(otp.attempts).to eq(0)
      expect(otp.expires_at).to be_within(5.seconds).of(20.minutes.from_now)
      expect(described_class.issue(users(:two), :invitation).expires_at).to be_within(5.seconds).of(7.days.from_now)
    end

    it "returns nil while the resend cooldown is running" do
      described_class.issue(user, :password_reset)

      expect(described_class.issue(user, :password_reset)).to be_nil
      expect(described_class.where(user: user).count).to eq(1)
    end

    it "keeps one code per purpose" do
      described_class.issue(user, :password_reset)

      expect(described_class.issue(user, :invitation)).to be_persisted
      expect(described_class.where(user: user).count).to eq(2)
    end

    it "replaces the previous code once the cooldown passes" do
      old_code = described_class.issue(user, :password_reset).code

      travel 6.minutes do
        new_otp = described_class.issue(user, :password_reset)

        expect(described_class.where(user: user).count).to eq(1)
        expect(described_class.verify(user, :password_reset, old_code)).to be(false)
        expect(described_class.verify(user, :password_reset, new_otp.code)).to be(true)
      end
    end

    it "resets the attempts when the code is replaced" do
      otp = described_class.issue(user, :password_reset)
      2.times { described_class.verify(user, :password_reset, "000000") }
      expect(otp.reload.attempts).to eq(2)

      travel(6.minutes) { described_class.issue(user, :password_reset) }

      expect(otp.reload.attempts).to eq(0)
    end
  end

  describe "#code" do
    it "is six digits for a password reset and a long token for an invitation" do
      expect(described_class.issue(user, :password_reset).code).to match(/\A\d{6}\z/)
      expect(described_class.issue(user, :invitation).code).to match(/\A\h{32}\z/)
    end

    it "is stable for the same record and is not stored in the database" do
      otp = described_class.issue(user, :password_reset)

      expect(otp.code).to eq(described_class.find(otp.id).code)
      expect(otp.attributes.values.map(&:to_s)).not_to include(otp.code)
    end

    it "depends on the user and the purpose" do
      reset = described_class.issue(user, :invitation).code

      expect(described_class.issue(users(:two), :invitation).code).not_to eq(reset)
      expect(described_class.issue(user, :password_reset).code).not_to eq(reset)
    end
  end

  describe ".verify" do
    let!(:otp) { described_class.issue(user, :password_reset) }

    it "accepts the right code and consumes it" do
      expect(described_class.verify(user, :password_reset, otp.code)).to be(true)
      expect(described_class.verify(user, :password_reset, otp.code)).to be(false)
      expect(described_class.exists?(otp.id)).to be(false)
    end

    it "rejects a wrong code and counts the attempt" do
      expect(described_class.verify(user, :password_reset, "abc")).to be(false)
      expect(otp.reload.attempts).to eq(1)
    end

    it "rejects an expired code" do
      travel(21.minutes) { expect(described_class.verify(user, :password_reset, otp.code)).to be(false) }
    end

    it "rejects even the right code after the attempts run out" do
      described_class::MAX_ATTEMPTS.times { described_class.verify(user, :password_reset, "000000") }

      expect(described_class.verify(user, :password_reset, otp.code)).to be(false)
      expect(otp.reload.attempts).to eq(described_class::MAX_ATTEMPTS)
    end

    it "rejects the code of another purpose or another user" do
      other = described_class.issue(users(:two), :password_reset)

      expect(described_class.verify(user, :invitation, otp.code)).to be(false)
      expect(described_class.verify(user, :password_reset, other.code)).to be(false)
    end

    it "rejects when the user has no code" do
      expect(described_class.verify(users(:two), :password_reset, "123456")).to be(false)
    end
  end

  describe ".check" do
    let!(:otp) { described_class.issue(user, :invitation) }

    it "accepts the right code without consuming it or counting an attempt" do
      expect(described_class.check(user, :invitation, otp.code)).to be(true)
      expect(described_class.check(user, :invitation, otp.code)).to be(true)
      expect(otp.reload.attempts).to eq(0)
    end

    it "rejects a wrong code, an expired code and a missing code" do
      expect(described_class.check(user, :invitation, "x" * 32)).to be(false)
      expect(described_class.check(users(:two), :invitation, otp.code)).to be(false)
      travel(8.days) { expect(described_class.check(user, :invitation, otp.code)).to be(false) }
    end
  end

  describe ".pending?" do
    it "is true only while there is an unexpired code" do
      expect(described_class.pending?(user, :invitation)).to be(false)

      described_class.issue(user, :invitation)
      expect(described_class.pending?(user, :invitation)).to be(true)
      travel(8.days) { expect(described_class.pending?(user, :invitation)).to be(false) }
    end
  end

  describe ".consume" do
    it "deletes the code of that purpose only" do
      described_class.issue(user, :invitation)
      described_class.issue(user, :password_reset)

      described_class.consume(user, :invitation)

      expect(described_class.pending?(user, :invitation)).to be(false)
      expect(described_class.pending?(user, :password_reset)).to be(true)
    end
  end
end
