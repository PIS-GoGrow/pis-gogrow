# frozen_string_literal: true

class WhatsappSenderJob < ApplicationJob
  ACCESS_TOKEN = "EAANPGR2dhSIBSgGjCptYcS4FKvWCQLNwZBZC8gFkWZAGYQhHyFLNSKVUbjg9CGwtCmTGaaBPxo9bNJRtR7ZCrES0S40J223wZA3DE4VD8Dq9Vw8HRjNVtlSzhkFoF8Xc181DrUlm4IX8RtEuhHm4XgIpOJ14cG0jNLYpti36Vr1BZCM23DXkJeUHf2SjNXm1bUsO6bhIl97d3xrYXmqtfZAvZC8ZBSh43rYjqOPybfEYSkdymnBxnmiZAK55eHKrHTrlStJtZCBpadHrM6yfJpKxjOq"
  PHONE_ID = "1295325710339793"

  queue_as :default

  def perform(event_key, title_data, description_data, phone, *args)
    conn = Faraday.new(
      url: "https://graph.facebook.com",
      headers: {
        'Authorization': 'Bearer ' + ACCESS_TOKEN,
        'Content-Type' => 'application/json'
      }
    )

    p conn.post("/v25.0/#{PHONE_ID}/messages", request_body(event_key, title_data, description_data, phone || "+59898163754"))
  end

  private

  def request_body(event_key, title_data, description_data, phone)
    {
      messaging_product: :whatsapp,
      to: phone,
      type: :template,
      template: {
        name: event_key,
        language: { code: :es },
        components: [
          {
            type: :body,
            parameters: named_parameters(description_data)
          },
          {
            type: :header,
            parameters: named_parameters(title_data)
          }
        ]
      }
    }.to_json
  end

  def named_parameters(data)
    data.map do |name, value|
      { type: "text", parameter_name: name.to_s, text: value.to_s }
    end
  end
end
