# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pantalla de error al confirmar un pedido", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules,
           :benefit_configurations, :benefits

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
    visit_hydrated dashboard_path
    without_animations
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def add_dish_to_cart
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"
  end

  def open_cart
    click_link "Ver carrito"
    expect(page).to have_current_path(/cart/)
    expect(page).to have_content("Tu carrito")
  end

  def expect_buttons_within_container_and_balanced
    bounds = page.evaluate_script(<<~JS)
      (() => {
        const retryBtn = Array.from(document.querySelectorAll("button")).find(b => b.textContent.trim() === "Reintentar");
        const menuBtn = Array.from(document.querySelectorAll("a, button")).find(b => b.textContent.trim() === "Volver a Menú");
        if (!retryBtn || !menuBtn) return null;

        const container = retryBtn.parentElement;
        const containerRect = container.getBoundingClientRect();
        const retryRect = retryBtn.getBoundingClientRect();
        const menuRect = menuBtn.getBoundingClientRect();

        return {
          retryLeft: retryRect.left,
          retryRight: retryRect.right,
          retryWidth: retryRect.width,
          menuLeft: menuRect.left,
          menuRight: menuRect.right,
          menuWidth: menuRect.width,
          containerLeft: containerRect.left,
          containerRight: containerRect.right,
          containerWidth: containerRect.width,
          retryHasFlex1: retryBtn.classList.contains("flex-1"),
          menuHasFlex1: menuBtn.classList.contains("flex-1"),
          retryHasWFull: retryBtn.classList.contains("w-full"),
          menuHasWFull: menuBtn.classList.contains("w-full")
        };
      })()
    JS

    expect(bounds).not_to be_nil
    # Verificamos clases flex-1 para reparto equitativo del ancho
    expect(bounds["retryHasFlex1"]).to be(true)
    expect(bounds["menuHasFlex1"]).to be(true)
    expect(bounds["retryHasWFull"]).to be(false)
    expect(bounds["menuHasWFull"]).to be(false)

    # El botón derecho (Volver a Menú) no debe desbordar hacia la derecha del contenedor
    expect(bounds["menuRight"]).to be <= (bounds["containerRight"] + 2)
    # El botón izquierdo (Reintentar) no debe desbordar hacia la izquierda del contenedor
    expect(bounds["retryLeft"]).to be >= (bounds["containerLeft"] - 2)
    # Ambos botones deben compartir el ancho de forma equitativa
    expect(bounds["retryWidth"]).to be_within(4).of(bounds["menuWidth"])
  end

  describe "Visualización y comportamiento de la pantalla de error" do
    it "centra la pantalla de error y mantiene ambos botones dentro de la tarjeta sin desbordar (reproducción PR #135)" do
      page.current_window.resize_to(375, 812) # Vista móvil típica

      add_dish_to_cart

      # Reproducción exacta del PR: cambiar id en sessionStorage a uno inexistente
      page.execute_script(<<~JS)
        const cart = JSON.parse(sessionStorage.getItem("cart") || "[]");
        if (cart.length > 0) {
          cart[0].id = 999999;
          sessionStorage.setItem("cart", JSON.stringify(cart));
        }
      JS
      page.refresh
      wait_for_hydration
      without_animations

      open_cart
      click_button "Confirmar pedido"

      # Pantalla de error
      expect(page).to have_content("No se pudo procesar el pedido")
      expect(page).to have_content(I18n.t("validations.cart_unavailable"))

      # Verificación de contención geométrica y clases flex-1
      expect_buttons_within_container_and_balanced

      # Acción Reintentar: vuelve a la vista del carrito
      click_button "Reintentar"
      expect(page).to have_content("Tu carrito")
    end

    it "muestra el error cuando el stock se agota antes de confirmar y permite volver al menú" do
      page.current_window.resize_to(1024, 768)

      add_dish_to_cart
      open_cart

      # En el backend el stock se agota concurrentemente
      Schedule.update_all(amount: 0)

      click_button "Confirmar pedido"

      expect(page).to have_content("No se pudo procesar el pedido")
      expect(page).to have_content(I18n.t("validations.insufficient_stock"))

      expect_buttons_within_container_and_balanced

      # Acción Volver a Menú: navega al dashboard de consumidor
      click_link "Volver a Menú"
      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Menú semanal")
    end
  end
end
