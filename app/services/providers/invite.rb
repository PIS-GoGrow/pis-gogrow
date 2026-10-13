# frozen_string_literal: true

module Providers
  class Invite
    class EmailTaken < StandardError; end

    def self.call(name:, email:, company:)
      user = User.find_by(email: email)
      raise EmailTaken if user && !(user.provider? && !user.verified?)

      user ||= User.new(name: name, email: email, password: SecureRandom.hex(32))

      ActiveRecord::Base.transaction do
        user.save!
        user.provider || Provider.create!(user: user)
      end

      otp = OtpCode.issue(user, :invitation)
      UserMailer.with(otp_code: otp, company: company).invitation.deliver_later if otp
      user
    end
  end
end
