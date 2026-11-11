# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PWA", type: :request do
  describe "GET /offline" do
    it "renders without a session and without setting a session cookie" do
      get "/offline"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<title>Sin conexión</title>")
      expect(response.headers["Set-Cookie"]).to be_blank
    end
  end

  describe "GET /manifest.json" do
    it "describes the installable app with icons whose declared size matches the file" do
      get pwa_manifest_path(format: :json)

      expect(response).to have_http_status(:ok)
      manifest = response.parsed_body
      expect(manifest).to include("name" => "Viandas GoGrow", "display" => "standalone", "start_url" => "/", "scope" => "/")

      manifest["icons"].each do |icon|
        width, height = File.binread(Rails.public_path.join(icon["src"].delete_prefix("/")), 24)[16, 8].unpack("NN")
        expect("#{width}x#{height}").to eq(icon["sizes"]), "#{icon["src"]} declara #{icon["sizes"]}"
      end
    end
  end

  describe "GET /service-worker.js" do
    it "serves the service worker as JavaScript without a session" do
      get pwa_service_worker_path(format: :js)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include('const OFFLINE_URL = "/offline"')
    end
  end
end
