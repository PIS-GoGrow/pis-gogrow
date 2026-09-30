# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

# IBP-014 — "Como EMPLEADO, quiero ingresar una dirección de entrega
# personalizada cuando el proveedor lo permita para recibir el pedido fuera de
# la oficina."
RSpec.describe "Delivery addresses", type: :request do
  fixtures :users, :consumers, :companies

  def address_params(save_for_later: true, **attributes)
    { delivery_address: { name: "Flora Café", street: "Canelones 892", apartment: "Apto 3", save_for_later:, **attributes } }
  end

  it "redirects visitors to the sign in page" do
    post delivery_addresses_path, params: address_params

    expect(response).to redirect_to(sign_in_path)
  end

  it "rejects a session with a different role" do
    sign_in users(:provider_user)

    expect { post delivery_addresses_path, params: address_params }.not_to change(DeliveryAddress, :count)
    expect(response).to redirect_to(root_path)
  end

  context "when signed in as an employee" do
    before { sign_in users(:one) }

    it "saves the address in the employee profile for future orders" do
      expect { post delivery_addresses_path, params: address_params }.to change(DeliveryAddress, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      expect(consumers(:one).saved_addresses.last)
        .to have_attributes(name: "Flora Café", street: "Canelones 892", apartment: "Apto 3")

      follow_redirect!
      expect(inertia.props[:addresses]).to include(
        a_hash_including(label: "Flora Café", address: "Canelones 892, Apto 3")
      )
    end

    it "only validates an address that is not saved for later" do
      expect { post delivery_addresses_path, params: address_params(save_for_later: false) }
        .not_to change(DeliveryAddress, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to be_blank
    end

    # Criterio 2: los campos obligatorios se validan antes de usar la dirección.
    it "returns the validation errors of the required fields" do
      expect { post delivery_addresses_path, params: address_params(name: "", street: "Canelones") }
        .not_to change(DeliveryAddress, :count)

      follow_redirect!
      expect(inertia.props[:errors]).to include(
        name: [ I18n.t("activerecord.errors.models.delivery_address.attributes.name.blank") ],
        street: [ I18n.t("activerecord.errors.models.delivery_address.attributes.street.invalid") ]
      )
    end

    it "validates the address even when it is not saved for later" do
      post delivery_addresses_path, params: address_params(save_for_later: false, street: "")

      follow_redirect!
      expect(inertia.props[:errors]).to include(
        street: [ I18n.t("activerecord.errors.models.delivery_address.attributes.street.blank") ]
      )
    end
  end
end
