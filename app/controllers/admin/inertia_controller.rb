# frozen_string_literal: true

class Admin::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:admin) }
end
