# frozen_string_literal: true

class SharedPropsSerializer < ApplicationSerializer
  one :auth, source: proc { Current }

  typelize locale: :string
  attribute :locale do
    I18n.locale.to_s
  end
end
