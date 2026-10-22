# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer reviews", type: :request do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders, :reviews

  let(:consumer_user) { users(:one) }
  let(:reviewable) { orders(:history_confirmed_past) }

  describe "GET /pedidos/:order_id/calificacion/nueva" do
    it "muestra el formulario para un pedido calificable" do
      sign_in consumer_user, role: :consumer

      get new_order_review_path(reviewable)

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("consumer/reviews/new")
      expect(inertia.props[:order][:id]).to eq(reviewable.id)
    end

    it "redirige al inicio de sesión cuando el visitante no está autenticado" do
      get new_order_review_path(reviewable)
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirige a la lista con un aviso para un pedido pendiente" do
      sign_in consumer_user, role: :consumer
      get new_order_review_path(orders(:history_pending_past))
      expect(response).to redirect_to(orders_path)
      expect(flash[:alert]).to eq(I18n.t("flash.review_unavailable"))
    end

    it "redirige a la lista para un pedido confirmado cuya entrega aún no pasó" do
      sign_in consumer_user, role: :consumer
      get new_order_review_path(orders(:upcoming_confirmed_future))
      expect(response).to redirect_to(orders_path)
    end

    it "redirige a la lista para un pedido cancelado" do
      sign_in consumer_user, role: :consumer
      get new_order_review_path(orders(:history_cancelled_future))
      expect(response).to redirect_to(orders_path)
    end

    it "devuelve 404 para un pedido de otro empleado" do
      sign_in consumer_user, role: :consumer
      get new_order_review_path(orders(:other_consumer_upcoming))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /pedidos/:order_id/calificacion" do
    before { sign_in consumer_user, role: :consumer }

    it "crea la calificación con puntuación y reseña, y lleva a la pantalla de agradecimiento" do
      expect {
        post order_review_path(reviewable), params: { rating: 5, description: "Muy rico" }
      }.to change(Review, :count).by(1)

      expect(response).to redirect_to(review_thanks_path)

      review = reviewable.reload.review
      expect(review).to have_attributes(
        rating: 5,
        description: "Muy rico",
        consumer: consumers(:one),
        menu: menus(:milanesa)
      )
    end

    it "permite omitir la reseña cuando hay puntuación" do
      expect {
        post order_review_path(reviewable), params: { rating: 4, description: "" }
      }.to change(Review, :count).by(1)

      expect(reviewable.reload.review.description).to be_nil
    end

    it "rechaza publicar sin puntuación y muestra los errores de validación" do
      expect {
        post order_review_path(reviewable), params: { rating: "", description: "Sin estrellas" }
      }.not_to change(Review, :count)

      expect(response).to redirect_to(new_order_review_path(reviewable))
      follow_redirect!
      expect(inertia.props[:errors][:rating]).to be_present
    end

    it "rechaza una reseña de más de 200 caracteres" do
      expect {
        post order_review_path(reviewable), params: { rating: 3, description: "a" * 201 }
      }.not_to change(Review, :count)

      expect(response).to redirect_to(new_order_review_path(reviewable))
      follow_redirect!
      expect(inertia.props[:errors][:description]).to be_present
    end

    it "no permite calificar dos veces el mismo pedido y redirige con un aviso" do
      post order_review_path(reviewable), params: { rating: 5 }

      expect {
        post order_review_path(reviewable), params: { rating: 1 }
      }.not_to change(Review, :count)
      expect(response).to redirect_to(orders_path)
      expect(flash[:alert]).to eq(I18n.t("flash.review_unavailable"))
    end

    it "redirige con un aviso para un pedido no calificable" do
      expect {
        post order_review_path(orders(:history_cancelled_future)), params: { rating: 5 }
      }.not_to change(Review, :count)
      expect(response).to redirect_to(orders_path)
    end
  end
end
