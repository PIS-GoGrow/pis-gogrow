# frozen_string_literal: true

class Provider::CollectionsIndexSerializer < ApplicationSerializer
  attributes :sales, :outstanding, :clients

  typelize sales: "{ total: number; meals: number }"
  typelize outstanding: "{ total: number; meals: number }"
  typelize clients: "Array<{ id: number; name: string }>"

  has_many :pending, resource: Provider::CollectionGroupSerializer
  has_many :history, resource: Provider::CollectionGroupSerializer
end
