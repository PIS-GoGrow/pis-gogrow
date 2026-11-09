# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", "from@example.com")
  layout "mailer"
end
