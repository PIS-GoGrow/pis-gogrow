# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

# IBP-014 — "Como EMPLEADO, quiero ingresar una dirección de entrega
# personalizada cuando el proveedor lo permita para recibir el pedido fuera de
# la oficina."
RSpec.describe "Delivery addresses", type: :request do
  fixtures :users, :consumers, :companies, :providers, :admins

  def address_params(save_for_later: true, **attributes)
    { delivery_address: { name: "Flora Café", street: "Canelones 892", apartment: "Apto 3", save_for_later:, **attributes } }
  end

  it "redirects visitors to the sign in page" do
    post delivery_addresses_path, params: address_params

    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects visitors on GET to the sign in page" do
    get delivery_addresses_path
    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects visitors on PATCH to the sign in page" do
    patch delivery_address_path(id: 1), params: address_params
    expect(response).to redirect_to(sign_in_path)
  end

  it "redirects visitors on DELETE to the sign in page" do
    delete delivery_address_path(id: 1)
    expect(response).to redirect_to(sign_in_path)
  end

  it "rejects a session with a provider role" do
    sign_in users(:provider_user)

    expect { post delivery_addresses_path, params: address_params }.not_to change(DeliveryAddress, :count)
    expect(response).to redirect_to(root_path)
  end

  it "rejects a session with an admin role" do
    sign_in users(:admin)

    get delivery_addresses_path
    expect(response).to redirect_to(root_path)
  end

  context "when signed in as an employee" do
    before { sign_in users(:one) }

    def home_order(address:)
      menu = Menu.create!(
        provider: providers(:tuviandita),
        name: "Milanesa",
        description: "Plato de prueba",
        price: 300
      )

      schedule = Schedule.create!(
        menu:,
        date: Date.current + 1.day,
        amount: 5
      )

      Order.create!(
        consumer: consumers(:one),
        schedule:,
        amount: 1,
        price: 300,
        address:,
        delivery_method: :home
      )
    end

    it "saves the address in the employee profile for future orders" do
      expect { post delivery_addresses_path, params: address_params }.to change(DeliveryAddress, :count).by(1)

      expect(response).to redirect_to(dashboard_cart_path)
      expect(consumers(:one).saved_addresses.last)
        .to have_attributes(name: "Flora Café", street: "Canelones 892", apartment: "Apto 3")

      get dashboard_cart_path
      expect(inertia.props[:addresses]).to include(
        a_hash_including(label: "Flora Café", address: "Canelones 892, Apto 3")
      )
    end

    it "goes back to the screen the employee came from" do
      post delivery_addresses_path, params: address_params, headers: { "HTTP_REFERER" => orders_url }

      expect(response).to redirect_to(orders_url)
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

    describe "GET /direcciones-de-entrega" do
      it "lists the office and the employee saved addresses" do
        own_address = consumers(:one).saved_addresses.create!(
          name: "Flora Café",
          street: "Canelones 892",
          apartment: "Apto 3"
        )

        get delivery_addresses_path

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("consumer/delivery_addresses/index")
        expect(inertia.props[:office_address]).to eq(consumers(:one).company.address)

        expect(inertia.props[:delivery_addresses]).to include(
          a_hash_including(
            id: own_address.id,
            name: "Flora Café",
            street: "Canelones 892",
            apartment: "Apto 3",
            address: "Canelones 892, Apto 3"
          )
        )
      end

      it "does not list another employee's addresses" do
        own_address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234"
        )

        other_address = consumers(:other).saved_addresses.create!(
          name: "Casa ajena",
          street: "Rivera 2000"
        )

        get delivery_addresses_path

        ids = inertia.props[:delivery_addresses].pluck(:id)

        expect(ids).to include(own_address.id)
        expect(ids).not_to include(other_address.id)
      end

      it "returns exact props with empty saved addresses list when employee has none" do
        consumers(:one).saved_addresses.delete_all

        get delivery_addresses_path

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("consumer/delivery_addresses/index")
        expect(inertia.props).to include(
          office_address: consumers(:one).company.address,
          delivery_addresses: []
        )
      end
    end

    describe "PATCH /direcciones-de-entrega/:id" do
      it "updates one of the employee addresses" do
        address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234"
        )

        patch delivery_address_path(address), params: {
          delivery_address: {
            name: "Casa nueva",
            street: "Rivera 2000",
            apartment: "Apto 4"
          }
        }

        expect(response).to redirect_to(delivery_addresses_path)
        expect(address.reload).to have_attributes(
          name: "Casa nueva",
          street: "Rivera 2000",
          apartment: "Apto 4"
        )
      end

      it "does not allow updating another employee's address" do
        address = consumers(:other).saved_addresses.create!(
          name: "Casa ajena",
          street: "Rivera 2000"
        )

        patch delivery_address_path(address), params: {
          delivery_address: {
            name: "Modificada",
            street: "Colonia 1500",
            apartment: ""
          }
        }

        expect(response).to have_http_status(:not_found)
        expect(address.reload).to have_attributes(
          name: "Casa ajena",
          street: "Rivera 2000"
        )
      end

      it "keeps previous orders with their original address" do
        address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234",
          apartment: "Apto 2"
        )

        original_address = address.full_address
        order = home_order(address: original_address)

        patch delivery_address_path(address), params: {
          delivery_address: {
            name: "Casa nueva",
            street: "Rivera 2000",
            apartment: "Apto 4"
          }
        }

        expect(response).to redirect_to(delivery_addresses_path)
        expect(address.reload.full_address).to eq("Rivera 2000, Apto 4")
        expect(order.reload.address).to eq(original_address)
      end

      it "returns validation errors for invalid data" do
        address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234"
        )

        patch delivery_address_path(address), params: {
          delivery_address: {
            name: "",
            street: "Canelones",
            apartment: ""
          }
        }

        expect(response).to redirect_to(delivery_addresses_path)

        follow_redirect!

        expect(inertia.props[:errors]).to include(
          name: [
            I18n.t(
              "activerecord.errors.models.delivery_address.attributes.name.blank"
            )
          ],
          street: [
            I18n.t(
              "activerecord.errors.models.delivery_address.attributes.street.invalid"
            )
          ]
        )

        expect(address.reload).to have_attributes(
          name: "Casa",
          street: "Ellauri 1234"
        )
      end

      it "returns 404 when updating a nonexistent address" do
        patch delivery_address_path(id: 999_999), params: {
          delivery_address: { name: "Nueva", street: "Colonia 1000" }
        }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /direcciones-de-entrega/:id" do
      it "deletes one of the employee addresses" do
        address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234"
        )

        expect {
          delete delivery_address_path(address)
        }.to change(DeliveryAddress, :count).by(-1)

        expect(response).to redirect_to(delivery_addresses_path)
      end

      it "does not allow deleting another employee's address" do
        address = consumers(:other).saved_addresses.create!(
          name: "Casa ajena",
          street: "Rivera 2000"
        )

        expect {
          delete delivery_address_path(address)
        }.not_to change(DeliveryAddress, :count)

        expect(response).to have_http_status(:not_found)
        expect(address.reload).to be_persisted
      end

      it "keeps previous orders with their original address" do
        address = consumers(:one).saved_addresses.create!(
          name: "Casa",
          street: "Ellauri 1234",
          apartment: "Apto 2"
        )

        original_address = address.full_address
        order = home_order(address: original_address)

        delete delivery_address_path(address)

        expect(response).to redirect_to(delivery_addresses_path)
        expect(DeliveryAddress.exists?(address.id)).to be(false)
        expect(order.reload.address).to eq(original_address)
      end

      it "returns 404 when deleting a nonexistent address" do
        delete delivery_address_path(id: 999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /direcciones-de-entrega from address management" do
      it "returns bad request when root parameter is missing" do
        post delivery_addresses_path, params: { source: "addresses" }

        expect(response).to have_http_status(:bad_request)
      end

      it "validates max length constraints directly sent to the endpoint" do
        post delivery_addresses_path,
             params: address_params(
               name: "a" * 41,
               street: "Calle #{"a" * 121} 1",
               apartment: "b" * 41
             ).merge(source: "addresses")

        expect(response).to redirect_to(delivery_addresses_path)
        follow_redirect!
        expect(inertia.props[:errors]).to include(:name, :street, :apartment)
      end

      it "saves an address from the address management page" do
        expect {
          post delivery_addresses_path,
              params: address_params(save_for_later: false).merge(source: "addresses")
        }.to change(consumers(:one).saved_addresses, :count).by(1)

        expect(response).to redirect_to(delivery_addresses_path)

        expect(consumers(:one).saved_addresses.last).to have_attributes(
          name: "Flora Café",
          street: "Canelones 892",
          apartment: "Apto 3"
        )
      end

      it "returns to address management with validation errors" do
        post delivery_addresses_path,
            params: address_params(
              save_for_later: false,
              name: "",
              street: ""
            ).merge(source: "addresses")

        expect(response).to redirect_to(delivery_addresses_path)

        follow_redirect!

        expect(inertia.props[:errors]).to include(:name, :street)
      end
    end
  end
end
