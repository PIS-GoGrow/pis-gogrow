# frozen_string_literal: true

class Provider::CollectionsIndexSerializer < ApplicationSerializer
  attributes :sales, :sales_detail, :outstanding, :clients

  typelize sales: "{ total: number; meals: number }"
  typelize sales_detail: "{ month: string; clients: Array<{ id: number; name: string }>; days: Array<{ date: string; orders: Array<{ id: number; consumer_name: string; client_id: number; client_name: string; meals: number; amount: number }> }> }"
  typelize outstanding: "{ total: number; meals: number }"
  typelize clients: "Array<{ id: number; name: string }>"

  has_many :pending, resource: Provider::CollectionGroupSerializer
  has_many :history, resource: Provider::CollectionGroupSerializer
end
