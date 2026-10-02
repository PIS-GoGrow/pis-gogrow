# frozen_string_literal: true

class Admin::ConsumerRowSerializer < ApplicationSerializer
  typelize id: :number, name: :string, email: :string, amount: :number
  attributes :id, :name, :email, :amount

  # Sigue el enum de Payment; escrito a mano porque acá no hay un modelo del que inferirlo.
  typelize "'pending' | 'submitted' | 'approved' | 'rejected' | null"
  attribute :status, &:status
end
