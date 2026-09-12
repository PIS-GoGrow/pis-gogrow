# frozen_string_literal: true

class Admin::InertiaController < InertiaController
  before_action :authenticate_admin
end

