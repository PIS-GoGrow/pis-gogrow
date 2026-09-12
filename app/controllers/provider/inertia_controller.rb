# frozen_string_literal: true

class Provider::InertiaController < InertiaController
  before_action :authenticate_provider
end
