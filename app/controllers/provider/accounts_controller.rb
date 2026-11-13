# frozen_string_literal: true

class Provider::AccountsController < Provider::InertiaController
  def show
    @incomplete_sections = Current.user.provider.incomplete_sections
  end
end
