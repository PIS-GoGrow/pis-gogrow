# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { Mail::Address.new(ENV.fetch("SMTP_FROM", "from@example.com")).tap { it.display_name = "Viandas" }.format }
  layout "mailer"

  private

  def attach_brand_images
    %w[logo-mark.png gogrow-wordmark.png].each do |name|
      attachments.inline[name] = File.binread(Rails.root.join("app/assets/images/mailers", name))
    end
  end
end
