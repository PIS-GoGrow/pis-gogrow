# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Detalle de plato en móvil no tapa cupones con barra de precios", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus,
           :benefit_configurations, :benefits

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:sorrentinos) { menus(:sorrentinos) }

  before do
    page.current_window.resize_to(375, 812)

    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    Schedule.create!(menu: sorrentinos, date: monday)

    benefit_configurations(:gift2, :seniority).each(&:destroy)
    benefits(:monthly).update!(
      percentage: 50,
      amount: 20,
      due_date: Date.current.end_of_month,
      status: :current
    )

    configuration = benefit_configurations(:gift)
    configuration.update!(name: "Premio del mes")
    @coupon = consumers(:one).benefits.create!(
      benefit_configuration: configuration,
      description: "Premio del mes",
      percentage: 30,
      amount: 2,
      starts_on: Date.current,
      due_date: Date.current + 4.days,
      status: :current
    )

    sign_in users(:one), role: :consumer
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def open_dish
    visit dashboard_path
    without_animations
    find_button("Agregar #{sorrentinos.name}").click
    find_button("Agregar #{sorrentinos.name}").click unless page.has_button?("Volver", wait: 2)
  end

  it "en formato móvil los controles de cupones no son tapados por la barra fija al destildar y volver a tildar" do
    open_dish

    coupon_cb = find("#benefit-checkbox-#{@coupon.id}")
    expect(coupon_cb[:"data-state"]).to eq("checked")
    expect(page).to have_text("Premio del mes (30%)")

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    expect(page).to have_content("Aplicar")

    coupon_cb.click
    expect(coupon_cb[:"data-state"]).to eq("unchecked")
    expect(page).to have_no_text("Premio del mes (30%)")

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    coupon_cb.click
    expect(coupon_cb[:"data-state"]).to eq("checked")
    expect(page).to have_text("Premio del mes (30%)")
  end

  it "en formato escritorio la barra de precios no interfiere con los controles" do
    page.current_window.resize_to(1400, 900)
    open_dish

    coupon_cb = find("#benefit-checkbox-#{@coupon.id}")
    expect(coupon_cb).to be_visible
    expect(page).to have_content("Aplicar")
    coupon_cb.click
    expect(coupon_cb[:"data-state"]).to eq("unchecked")
  end
end
