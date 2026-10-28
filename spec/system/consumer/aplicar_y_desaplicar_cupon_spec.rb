# frozen_string_literal: true

require "rails_helper"

# Historia IBP-079: "Como EMPLEADO, quiero aplicar mis cupones al realizar un
# pedido y que se muestre el descuento."
# AC1: puedo aplicar un cupón a un pedido.
# AC2: puedo desaplicar un cupón a un pedido.
#
# TODO(integración): falta implementar desaplicar el cupón de un pedido YA
# confirmado desde "Mi pedido". `EditOrderSheet` no tiene control de beneficios y
# `Consumer::OrdersController#update` solo acepta quantity, notes, address y
# options, aunque `Order#modify` ya recalcula y reemplaza beneficios
# (`Order#replace_benefits!`). Cuando el formulario envíe los beneficios
# elegidos, convertir este comentario en el escenario "desaplico el cupón de un
# pedido confirmado, se me devuelven los usos y el importe vuelve al precio con
# subsidio base".
RSpec.describe "Aplicar y desaplicar un cupón al pedir", type: :system do
  fixtures :users, :companies, :admins, :consumers, :providers,
           :benefit_configurations, :benefit_rules, :benefits, :orders

  let(:consumer) { consumers(:one) }
  let(:menu) do
    Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan",
                 description: "Con papas", price: 300)
  end

  around do |example|
# El navegador no ve travel_to: el menú abre en el día real.
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
# gift2 y seniority son subsidios especiales sin nombre que la pantalla de
# RRHH mostraría vacíos; gift queda como el cupón de esta historia.
    benefit_configurations(:gift2, :seniority).each(&:destroy)
    benefits(:monthly).update!(percentage: 50, amount: 20,
                               due_date: Date.current.end_of_month, status: :current)
    Schedule.create!(menu:, date: Date.current, amount: 10)
  end

  def assign_coupon(amount: 2)
# El nombre que se muestra en el resumen de descuentos sale de la
# configuración (`order_pricing_serializer.rb`), no del cupón.
    configuration = benefit_configurations(:gift)
    configuration.update!(name: "Premio del mes")
    @coupon = consumer.benefits.create!(
      benefit_configuration: configuration,
      description: "Premio del mes",
      percentage: 30,
      amount: amount,
      starts_on: Date.current,
      due_date: Date.current + 4.days
    )
  end

  def open_dish
    visit dashboard_path
    without_animations
    click_button "Agregar Milanesa al pan"
    click_button "Agregar Milanesa al pan" unless page.has_button?("Volver", wait: 2)
  end

  def coupon_checkbox
    find("#benefit-checkbox-#{@coupon.id}")
  end

  def tier(label)
    find("span", text: label, exact_text: true).sibling("span")
  end

  it "aplica el cupón y el descuento se mantiene en el plato, el carrito y el pedido guardado" do
    assign_coupon
    sign_in users(:one), role: :consumer
    open_dish

    expect(coupon_checkbox[:"data-state"]).to eq("checked")

# 300 con 50% base (- $150) y 30% de cupón (- $90): paga 60.
    expect(tier("Subsidio Base (50%)")).to have_text("- $150")
    expect(tier("Premio del mes (30%)")).to have_text("- $90")
    expect(tier("Monto a pagar")).to have_text("$60")

    click_button "Agregar"
    click_link "Ver carrito"
    expect(tier("Monto a pagar")).to have_text("$60")

# El carrito vive en sessionStorage: al recargar, el cupón elegido tiene que
# seguir viajando al cálculo del servidor.
    page.refresh
    expect(tier("Monto a pagar")).to have_text("$60")

    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
    expect(find("p", text: "Monto a pagar", exact_text: true).sibling("p")).to have_text("$60")

    order = Order.last
    expect(order).to have_attributes(price: 300, discounted_price: 60)
    expect(order.order_benefits.pluck(:benefit_id, :benefit_used)).to contain_exactly(
      [ benefits(:monthly).id, 1 ], [ @coupon.id, 1 ]
    )

    visit order_path(order)
    expect(find("dt", text: "Beneficio aplicado").find(:xpath, "following-sibling::dd")).to have_text("240")
    expect(find("dt", text: "Importe final").find(:xpath, "following-sibling::dd")).to have_text("60")

    visit profile_path
    within("section[aria-labelledby=coupons-title]") do
      expect(find("dt", text: "Te quedan").find(:xpath, "following-sibling::dd")).to have_text("1 vianda")
    end
  end

  it "desaplica el cupón y el pedido se guarda sin ese descuento ni consumir sus usos" do
    assign_coupon
    sign_in users(:one), role: :consumer
    open_dish

    coupon_checkbox.click
    expect(coupon_checkbox[:"data-state"]).to eq("unchecked")

# 300 con 50% base (- $150), sin el cupón: paga 150.
    expect(page).to have_no_text("Premio del mes (30%)")
    expect(tier("Subsidio Base (50%)")).to have_text("- $150")
    expect(tier("Monto a pagar")).to have_text("$150")

    click_button "Agregar"
    click_link "Ver carrito"
    expect(page).to have_no_text("Premio del mes (30%)")
    expect(tier("Monto a pagar")).to have_text("$150")

    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")

    order = Order.last
    expect(order).to have_attributes(price: 300, discounted_price: 150)
    expect(order.order_benefits.pluck(:benefit_id)).to contain_exactly(benefits(:monthly).id)

    visit order_path(order)
    expect(find("dt", text: "Beneficio aplicado").find(:xpath, "following-sibling::dd")).to have_text("150")
    expect(find("dt", text: "Importe final").find(:xpath, "following-sibling::dd")).to have_text("150")

    visit profile_path
    within("section[aria-labelledby=coupons-title]") do
      expect(find("dt", text: "Te quedan").find(:xpath, "following-sibling::dd")).to have_text("2 viandas")
    end
  end

  it "no ofrece un cupón que ya agotó sus usos" do
    assign_coupon(amount: 1)
    OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: @coupon, benefit_used: 1)

    sign_in users(:one), role: :consumer
    open_dish

    expect(page).to have_no_css("#benefit-checkbox-#{@coupon.id}")
    expect(tier("Monto a pagar")).to have_text("$150")

    click_button "Agregar"
    click_link "Ver carrito"
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")

    expect(Order.last.order_benefits.pluck(:benefit_id)).to contain_exactly(benefits(:monthly).id)
  end

# El aislamiento entre empleados ya está cubierto por
# `spec/system/admin/asignar_cupon_spec.rb` ("solo el empleado elegido recibe el
# aviso…"): otro consumidor no ve el cupón ni el bloque "Mis cupones".
it "no deja que un proveedor entre al menú del empleado a usar cupones" do
    assign_coupon

    sign_in users(:provider_user), role: :provider
    visit dashboard_path
    without_animations

    expect(page).to have_current_path(provider_dashboard_path)
    expect(page).to have_no_css("#benefit-checkbox-#{@coupon.id}")
  end
end
