# frozen_string_literal: true

class Consumer::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:consumer) }
end
