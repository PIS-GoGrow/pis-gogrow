# frozen_string_literal: true

class Provider::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:provider) }
end
