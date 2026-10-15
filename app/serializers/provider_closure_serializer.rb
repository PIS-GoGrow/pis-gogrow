# frozen_string_literal: true

class ProviderClosureSerializer < ApplicationSerializer
  typelize_from ProviderClosure

  attributes :id, :starts_on, :ends_on, :reason

  # Formateado en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :period do |closure|
    from = closure.starts_on
    to = closure.ends_on
    day_month = ->(date) { I18n.l(date, format: :day_month).downcase }
    day_month_year = ->(date) { I18n.l(date, format: :day_month_year).downcase }

    key, values =
      if from == to
        [ :single, { date: day_month_year.(from) } ]
      elsif from.year == to.year && from.month == to.month
        [ :same_month, { from_day: from.day, to_day_month: day_month.(to), year: to.year } ]
      elsif from.year == to.year
        [ :same_year, { from_day_month: day_month.(from), to_day_month: day_month.(to), year: to.year } ]
      else
        [ :other_year, { from: day_month_year.(from), to: day_month_year.(to) } ]
      end

    I18n.t("pages.provider_operational_settings.show.closures.period.#{key}", **values)
  end
end

# == Schema Information
#
# Table name: provider_closures
#
#  id          :bigint           not null, primary key
#  ends_on     :date             not null
#  reason      :string           not null
#  starts_on   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_provider_closures_on_provider_id                (provider_id)
#  index_provider_closures_on_provider_id_and_starts_on  (provider_id,starts_on)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
