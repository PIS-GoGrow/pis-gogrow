# frozen_string_literal: true

class InertiaController < ApplicationController
  include Alba::Inertia::Controller

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  inertia_share { SharedPropsSerializer.new(self).to_inertia }

  private

  def render_not_found
    render inertia: "errors/not_found", props: {}, status: :not_found
  end
end
