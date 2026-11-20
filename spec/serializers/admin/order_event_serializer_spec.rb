# frozen_string_literal: true

require "rails_helper"

# IBP-038 CA2: el valor anterior y el nuevo se muestran como los lee RR. HH.,
# no como se guardan.
RSpec.describe Admin::OrderEventSerializer do
  fixtures :companies, :users, :consumers, :providers, :orders

  def changes_for(changeset)
    event = OrderEvent.create!(order_id: 1, company: companies(:gogrow), action: :modified, changeset:)
    described_class.new(event).to_h["changes"]
  end

  it "shows the delivery method, the rejection reason and the chosen options in words" do
    changes = changes_for(
      "delivery_method" => %w[office home],
      "rejection_reason" => [ nil, "out_of_stock" ],
      "selected_options" => [
        [ { "name" => "Salsa", "values" => [ "Filetto" ] } ],
        [ { "name" => "Salsa", "values" => [ "Bolognesa" ] }, { "name" => "Queso", "values" => [ "Parmesano", "Sin sal" ] } ]
      ]
    )

    expect(changes).to eq([
      { field: "delivery_method", before: I18n.t("pages.orders.delivery_methods.office"), after: I18n.t("pages.orders.delivery_methods.home") },
      { field: "rejection_reason", before: nil, after: I18n.t("pages.provider_orders.rejection_reasons.out_of_stock") },
      { field: "selected_options", before: "Filetto", after: "Bolognesa, Parmesano, Sin sal" }
    ])
  end

  # Los eventos de creación grabados antes del arreglo guardaron el default crudo
  # de status (0) como valor anterior, y el registro no se puede corregir.
  it "shows no previous value for a creation, even one recorded with the raw status default" do
    event = OrderEvent.create!(
      order_id: 1, company: companies(:gogrow), action: :created,
      changeset: { "status" => [ 0, "pending" ], "amount" => [ nil, 1 ] }
    )

    expect(described_class.new(event).to_h["changes"]).to eq([
      { field: "status", before: nil, after: I18n.t("pages.orders.statuses.pending") },
      { field: "amount", before: nil, after: "1" }
    ])
  end

  describe "counterpart and delivery date" do
    let(:order) { orders(:upcoming_pending_future) }

    it "formats the delivery date in dd/mm/yyyy" do
      event = OrderEvent.create!(order_id: order.id, company: order.consumer.company, action: :created, changeset: {})
      serialized = described_class.new(event).to_h

      expect(serialized["delivery_date"]).to eq(I18n.l(order.delivery_date, format: "%d/%m/%Y"))
    end

    it "handles missing delivery date or nil order gracefully" do
      event_no_order = OrderEvent.create!(order_id: 0, company: companies(:gogrow), action: :created, changeset: {})
      serialized = described_class.new(event_no_order).to_h

      expect(serialized["delivery_date"]).to be_nil
      expect(serialized["counterpart_name"]).to be_nil
      expect(serialized["counterpart_role"]).to eq("provider")
    end

    it "sets counterpart to consumer when the actor is a provider" do
      event = OrderEvent.create!(
        order_id: order.id, company: order.consumer.company, action: :confirmed,
        role: :provider, changeset: {}
      )
      serialized = described_class.new(event).to_h

      expect(serialized["counterpart_role"]).to eq("consumer")
      expect(serialized["counterpart_name"]).to eq(order.consumer.user.name)
    end

    it "sets counterpart to provider when the actor is a consumer" do
      event = OrderEvent.create!(
        order_id: order.id, company: order.consumer.company, action: :modified,
        role: :consumer, changeset: {}
      )
      serialized = described_class.new(event).to_h

      expect(serialized["counterpart_role"]).to eq("provider")
      expect(serialized["counterpart_name"]).to eq(order.provider_name)
    end

    it "sets counterpart to provider when the event is triggered by the system (no role)" do
      event = OrderEvent.create!(
        order_id: order.id, company: order.consumer.company, action: :price_changed,
        role: nil, changeset: {}
      )
      serialized = described_class.new(event).to_h

      expect(serialized["counterpart_role"]).to eq("provider")
      expect(serialized["counterpart_name"]).to eq(order.provider_name)
    end

    it "sets counterpart to provider when the event is triggered by an admin" do
      event = OrderEvent.create!(
        order_id: order.id, company: order.consumer.company, action: :modified,
        role: :admin, changeset: {}
      )
      serialized = described_class.new(event).to_h

      expect(serialized["counterpart_role"]).to eq("provider")
      expect(serialized["counterpart_name"]).to eq(order.provider_name)
    end
  end
end
