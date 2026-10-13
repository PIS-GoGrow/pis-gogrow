# frozen_string_literal: true

class WhatsappSenderJob < ApplicationJob
  ACCESS_TOKEN = "."
  PHONE_ID = "."

  queue_as :default

  # En progreso
  def perform(event_key, title_data, description_data, phone, *args)
    #conn = Faraday.new(
    #  url: 'https://graph.facebook.com/',
    #  headers: {
    #    'Authorization': 'Bearer ' + ACCESS_TOKEN,
    #    'Content-Type' => 'application/json'
    #  }
    #)

    #p conn.post("/v25.0/#{PHONE_ID}/messages", request_body(event_key, title_data, description_data, phone || "+59898163754"))
  end

  private

  def request_body(event_key, title_data, description_data, phone)
    {
      messaging_product: :whatsapp,
      to: phone,
      type: :template,
      template: {
        name: event_key,
        language: { code: :es_URY },
        components: [
          {
            type: :body,
            parameters: description_data
          },
          {
            type: :title,
            parameters: title_data
          }
        ]
      }
    }.to_json
  end
end
