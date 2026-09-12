# frozen_string_literal: true

class Consumer::InertiaController < InertiaController
  before_action :authenticate_consumer
end
