# frozen_string_literal: true

class WhatsappSenderJob < ApplicationJob
  ACCESS_TOKEN = "."
  PHONE_ID = "."

  queue_as :default

  def perform(content, phone, *args)
    conn = Faraday.new(
      url: "https://graph.facebook.com/",
      headers: {
        'Authorization': "Bearer " + ACCESS_TOKEN,
        "Content-Type" => "application/json"
      }
    )

    # p conn.post("/v25.0/#{PHONE_ID}/messages", request_body(phone))
  end

  private

  def request_body(phone)
    {
      messaging_product: :whatsapp,
      to: phone,
      type: :template,
      template: {
        name: :jaspers_market_order_confirmation_v1,
        language: { code: :en_US },
        components: [
          {
            type: :body,
            parameters: [
              { type: "text", text: "John Doe" },
              { type: "text", text: "123456" },
              { type: "text", text: "Oct 10, 2026" }
            ]
          }
        ]
      }
    }.to_json
  end
end
