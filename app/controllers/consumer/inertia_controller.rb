# frozen_string_literal: true

class Consumer::InertiaController < InertiaController
  before_action :set_role
  before_action :authenticate_consumer

  private

  def set_role
    Current.role = "consumer"
  end
end
