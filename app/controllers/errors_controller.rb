# frozen_string_literal: true

class ErrorsController < InertiaController
  skip_before_action :authenticate
  before_action :perform_authentication, only: :not_found

  def not_found
    self.status = :not_found
  end

  def internal_server_error
    self.status = :internal_server_error
  end
end
