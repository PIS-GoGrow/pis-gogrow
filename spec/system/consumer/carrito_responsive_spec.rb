# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Carrito responsive del consumidor", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :benefit_configurations, :benefits

  let(:monday) { Date.current.beginning_of_week(:monday) }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).beginning_of_day + 10.hours) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    Schedule.create!(menu: menus(:milanesa), date: monday, amount: 10)
    sign_in users(:one), role: :consumer
    visit dashboard_path
    page.execute_script("window.localStorage.setItem('sidebar', 'false')")
    page.refresh
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def resize_to(width)
    page.current_window.resize_to(width, 900)
  end

  def visible_cart_buttons
    all(:button, "Ver carrito", exact: true, visible: true)
  end

  def add_milanesa
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"
  end

  def expect_no_overlap(first_selector, second_selector)
    overlaps = page.evaluate_script(<<~JS)
      (() => {
        const first = document.querySelector(#{first_selector.to_json});
        const second = [...document.querySelectorAll(#{second_selector.to_json})]
          .find((element) => element.getClientRects().length > 0);
        if (!first || !second) return null;

        const a = first.getBoundingClientRect();
        const b = second.getBoundingClientRect();
        return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
      })()
    JS

    expect(overlaps).to be(false)
  end

  def expect_cart_within_sidebar_inset
    bounds = page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector("button.fixed");
        const inset = document.querySelector('[data-slot="sidebar-inset"]');
        const menu = document.querySelector("div.max-w-300");
        const sidebar = document.querySelector('[data-slot="sidebar-container"]');
        if (!button || !inset || !menu || !sidebar) return null;

        const buttonRect = button.getBoundingClientRect();
        const insetRect = inset.getBoundingClientRect();
        const sidebarRect = sidebar.getBoundingClientRect();
        const menuStyle = getComputedStyle(menu);
        const expectedMargin = parseFloat(menuStyle.paddingLeft);
        return {
          buttonLeft: buttonRect.left,
          buttonRight: buttonRect.right,
          insetLeft: insetRect.left,
          insetRight: insetRect.right,
          sidebarRight: sidebarRect.right,
          leftMargin: buttonRect.left - insetRect.left,
          rightMargin: insetRect.right - buttonRect.right,
          expectedMargin,
        };
      })()
    JS

    expect(bounds).not_to be_nil
    expect(bounds["buttonLeft"]).to be >= bounds["insetLeft"]
    expect(bounds["buttonLeft"]).to be >= bounds["sidebarRight"]
    expect(bounds["buttonRight"]).to be <= bounds["insetRight"]
    expect(bounds["leftMargin"]).to be_within(1).of(bounds["expectedMargin"])
    expect(bounds["rightMargin"]).to be_within(1).of(bounds["expectedMargin"])
  end

  def wait_for_sidebar_transition
    page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1];
      const elements = [
        '[data-slot="sidebar-gap"]',
        '[data-slot="sidebar-container"]',
        '[data-slot="sidebar-inset"]',
        '[data-slot="floating-cart-button"]',
      ].map((selector) => document.querySelector(selector)).filter(Boolean);
      const milliseconds = (value) => value.endsWith("ms")
        ? parseFloat(value)
        : parseFloat(value) * 1000;
      const transitionTime = elements.reduce((maximum, element) => {
        const style = getComputedStyle(element);
        const durations = style.transitionDuration.split(",").map(milliseconds);
        const delays = style.transitionDelay.split(",").map(milliseconds);
        const total = durations.map((duration, index) =>
          duration + (delays[index] ?? delays[0] ?? 0)
        );
        return Math.max(maximum, ...total);
      }, 0);

      window.setTimeout(done, transitionTime + 50);
    JS
  end

  def expect_tablet_cart_in_both_sidebar_states
    expect(page).to have_css("[data-slot='sidebar'][data-state='collapsed']")
    wait_for_sidebar_transition
    expect_cart_within_sidebar_inset
    expect_no_overlap("button.fixed", "[data-sidebar='sidebar']")

    find("[data-sidebar='trigger']").click
    expect(page).to have_css("[data-slot='sidebar'][data-state='expanded']")
    wait_for_sidebar_transition
    expect_cart_within_sidebar_inset
    expect_no_overlap("button.fixed", "[data-sidebar='sidebar']")

    find("[data-sidebar='trigger']").click
    expect(page).to have_css("[data-slot='sidebar'][data-state='collapsed']")
    wait_for_sidebar_transition
  end

  it "mantiene un único acceso funcional al carrito en todos los breakpoints" do
    [ 375, 820, 1000, 1024, 1400 ].each do |width|
      resize_to(width)
      expect(page).to have_no_css("button.fixed", text: "Ver carrito", visible: true)
    end

    resize_to(375)
    add_milanesa

    [ 375, 820, 1000, 1024, 1400 ].each do |width|
      resize_to(width)

      expect(visible_cart_buttons.size).to eq(1)

      if width < 1024
        expect(page).to have_css("button.fixed", text: "Ver carrito", visible: true)
        expect(page.evaluate_script("getComputedStyle(document.querySelector('button.fixed')).position")).to eq("fixed")

        if width < 768
          expect(page).to have_css("nav.fixed", visible: true)
          expect_no_overlap("button.fixed", "nav.fixed")
        else
          expect(page).to have_css("[data-sidebar='sidebar']", visible: true)
          expect_tablet_cart_in_both_sidebar_states
        end
      else
        expect(page).to have_no_css("button.fixed", text: "Ver carrito", visible: true)
        expect(page).to have_css("aside button", text: "Ver carrito", visible: true)
      end

      visible_cart_buttons.first.click
      expect(page).to have_content("Tu carrito")
      expect(page).to have_content("Milanesa con papas fritas x1")
      expect(page).to have_button("Confirmar pedido", disabled: false)
      click_button "Volver"
    end
  end
end
