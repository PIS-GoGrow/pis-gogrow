class PwaController < ApplicationController
  skip_before_action :authenticate
  skip_forgery_protection

  layout false

  def index
    render :index
  end

  def service_worker
    render template: "pwa/service-worker", formats: [:js],
           layout: false, content_type: "text/javascript"
  end

  def manifest
    render template: "pwa/manifest", formats: [:json],
           layout: false, content_type: "application/manifest+json"
  end
end
