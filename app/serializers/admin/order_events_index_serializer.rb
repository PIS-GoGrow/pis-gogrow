# frozen_string_literal: true

class Admin::OrderEventsIndexSerializer < ApplicationSerializer
  typelize total: :number,
           filters: "{ order_id?: string; event_action?: string; role?: string; from?: string; to?: string; actor?: string }"
  attributes :total, :filters

  has_many :events, resource: Admin::OrderEventSerializer
end
