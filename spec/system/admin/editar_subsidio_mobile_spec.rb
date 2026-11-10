# frozen_string_literal: true

require "rails_helper"

# Regresión del defecto de visibilidad del formulario de edición del Subsidio
# Base en mobile: los inputs numéricos tienen que mostrar valores de tres cifras
# completos a 390 px y, por debajo de 375 px, los campos y los botones tienen que
# apilarse sin generar scroll horizontal.
RSpec.describe "Editar el Subsidio Base en mobile", type: :system do
  fixtures :users, :companies, :admins, :benefit_configurations, :benefit_rules

  let(:admin_user) { users(:admin) }

  before { sign_in admin_user, role: :admin }

  def open_editor
    click_button "Editar"
    return if page.has_field?("subsidy_percentage", wait: 2)

    click_button "Editar"
    expect(page).to have_field("subsidy_percentage")
  end

  def fill_three_digit_values
    fill_in "subsidy_percentage", with: "100"
    fill_in "max_voucher_price", with: "500"
    fill_in "monthly_voucher_limit", with: "100"
  end

  def no_horizontal_overflow?
    page.evaluate_script(
      "document.documentElement.scrollWidth <= document.documentElement.clientWidth"
    )
  end

  it "muestra los valores de tres cifras completos a 390 px" do
    page.current_window.resize_to(390, 844)
    visit_hydrated admin_benefit_configurations_path
    without_animations
    open_editor

    fill_three_digit_values

    {
      "subsidy_percentage" => "100",
      "max_voucher_price" => "500",
      "monthly_voucher_limit" => "100"
    }.each do |id, value|
      field = find_field(id)
      expect(field.value).to eq(value)
      expect(field.native.size.width).to be >= 72
    end

    expect(no_horizontal_overflow?).to be(true)
    expect(page).to have_button("Cancelar")
    expect(page).to have_css("button[aria-label='Programar Subsidio']")
  end

  it "apila campos y botones sin desbordar a 375 px" do
    page.current_window.resize_to(375, 667)
    visit_hydrated admin_benefit_configurations_path
    without_animations
    open_editor

    fill_three_digit_values

    label = find("label[for='subsidy_percentage']")
    input = find_field("subsidy_percentage")
    expect(input.native.rect.y).to be > label.native.rect.y

    expect(no_horizontal_overflow?).to be(true)

    cancel = find_button("Cancelar")
    submit = find("button[aria-label='Programar Subsidio']")
    expect(submit.native.rect.y).to be > cancel.native.rect.y
    expect(submit.native.rect.x + submit.native.rect.width).to be <= 375
    expect(cancel.native.rect.x + cancel.native.rect.width).to be <= 375
  end
end
