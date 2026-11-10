# frozen_string_literal: true

class PwaController < ApplicationController
  skip_before_action :authenticate
  layout false

  def offline
    request.session_options[:skip] = true
    render :offline
  end
end
