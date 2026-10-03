# frozen_string_literal: true

class EmployeeSerializer < ApplicationSerializer
  typelize_from Consumer

  attributes :id

  typelize :string
  attribute :name do |consumer|
    consumer.user.name
  end

  # Nombre e inicial del apellido ("Matías R."), como en los chips del formulario.
  typelize :string
  attribute :short_name do |consumer|
    first, *rest = consumer.user.name.split
    rest.empty? ? first : "#{first} #{rest.last[0]}."
  end
end
