# frozen_string_literal: true

class WhatsappSenderJob < ApplicationJob
  queue_as :default

  def perform(event_key, title_data, description_data, phone, *args)
    account_sid = ENV.fetch("ACCOUNT_SID", nil)
    auth_token = ENV.fetch("AUTH_TOKEN", nil)
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    message = @client.messages.create(
      from: 'whatsapp:+14155238886',
      content_sid: 'HX806fcc7c9656b3968428a658160ed9f6',
      content_variables: '{"1":"12/1","2":"3pm"}',
      to: 'whatsapp:+59898163754'
    )

    puts message.sid
  end
end
