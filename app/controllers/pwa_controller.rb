class PwaController < ApplicationController
  skip_before_action :authenticate

  layout false

  def offline
    render :offline
  end
end
