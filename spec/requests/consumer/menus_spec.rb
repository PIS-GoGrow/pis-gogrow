# frozen_string_literal: true

require "rails_helper"

# Historia IBP-003: "Como EMPLEADO quiero consultar en un único lugar el menú
# disponible para una fecha, incluyendo las opciones de todos los proveedores".
RSpec.describe "Consumer::Menus", type: :request do
  fixtures :users

  let(:empleado) { users(:empleado) }
  let(:fecha) { Date.new(2026, 9, 21) }

  let!(:consumer) { create(:consumer, user: empleado) }
  let(:sabores) { create(:provider, user: users(:proveedor_sabores)) }
  let(:verde) { create(:provider, user: users(:proveedor_verde)) }

  def schedule_for(provider, date:, name:, amount: 10)
    create(:schedule, date: date, amount: amount, menu: create(:menu, name: name, provider: provider))
  end

  describe "GET /menus" do
    context "como empleado" do
      before { sign_in empleado }

      # AC1 — los platos de todos los proveedores llegan en una sola respuesta.
      it "reúne en una misma respuesta los platos de todos los proveedores para la fecha" do
        schedule_for(sabores, date: fecha, name: "Milanesa con puré")
        schedule_for(verde, date: fecha, name: "Tarta de zapallo")

        get menus_path, params: { date: fecha.to_s }

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("consumer/menus/index")
        expect(inertia.props[:schedules].map { |s| s[:menu][:name] })
          .to contain_exactly("Milanesa con puré", "Tarta de zapallo")
        expect(inertia.props[:schedules].map { |s| s[:menu][:provider][:name] })
          .to contain_exactly("Sabores del Sur", "Cocina Verde")
      end

      # AC1 — cada plato viaja con lo que la pantalla necesita mostrar.
      it "incluye nombre, descripción, precio y proveedor de cada plato" do
        schedule_for(sabores, date: fecha, name: "Milanesa con puré")

        get menus_path, params: { date: fecha.to_s }

        plato = inertia.props[:schedules].first
        expect(plato[:menu]).to include(:id, :name, :description, :price)
        expect(plato[:menu][:provider]).to include(name: "Sabores del Sur")
      end

      # AC2 — solo la fecha pedida, con los bordes N-1 y N+1 explícitos.
      it "excluye los platos del día anterior y del día siguiente" do
        schedule_for(sabores, date: fecha, name: "Del día")
        schedule_for(sabores, date: fecha - 1, name: "Del día anterior")
        schedule_for(sabores, date: fecha + 1, name: "Del día siguiente")

        get menus_path, params: { date: fecha.to_s }

        expect(inertia.props[:schedules].map { |s| s[:menu][:name] }).to eq([ "Del día" ])
        expect(inertia.props[:date]).to eq(fecha.to_s)
      end

      it "usa la fecha de hoy cuando no se envía el parámetro" do
        travel_to Date.new(2026, 9, 21) do
          schedule_for(sabores, date: Date.current, name: "De hoy")
          schedule_for(sabores, date: Date.current + 1, name: "De mañana")

          get menus_path

          expect(inertia.props[:date]).to eq(Date.current.to_s)
          expect(inertia.props[:schedules].map { |s| s[:menu][:name] }).to eq([ "De hoy" ])
        end
      end

      # AC3 — el server manda el cupo; quién se muestra "Agotado" lo decide la vista
      # a partir de este valor, así que lo que se verifica acá es que el 0 llegue como 0
      # y no se confunda con "sin límite" (nil).
      it "envía el cupo tal cual, distinguiendo agotado (0) de sin límite (nil)" do
        schedule_for(sabores, date: fecha, name: "Agotado", amount: 0)
        schedule_for(verde, date: fecha, name: "Sin límite", amount: nil)

        get menus_path, params: { date: fecha.to_s }

        cupos = inertia.props[:schedules].to_h { |s| [ s[:menu][:name], s[:amount] ] }
        expect(cupos).to eq("Agotado" => 0, "Sin límite" => nil)
      end

      # AC4 — sin menú publicado no hay error ni lista a medias: llega vacío.
      it "responde con la lista vacía cuando no hay nada publicado para la fecha" do
        schedule_for(sabores, date: fecha + 1, name: "Otro día")

        get menus_path, params: { date: fecha.to_s }

        expect(response).to have_http_status(:success)
        expect(inertia.props[:schedules]).to be_empty
      end

      it "expone los proveedores disponibles para el filtro de la pantalla" do
        schedule_for(sabores, date: fecha, name: "Milanesa con puré")
        verde

        get menus_path, params: { date: fecha.to_s }

        expect(inertia.props[:providers].map { |p| p[:name] })
          .to contain_exactly("Sabores del Sur", "Cocina Verde")
      end
    end

    # Transversal — permisos: la pantalla es del empleado, nadie más entra por URL directa.
    context "sin el rol de empleado" do
      it "redirige al login a un proveedor que entra por URL directa" do
        proveedor_user = users(:proveedor_sabores)
        create(:provider, user: proveedor_user)
        sign_in proveedor_user

        get menus_path

        expect(response).to redirect_to(sign_in_path)
      end

      it "redirige al login a un visitante sin sesión" do
        get menus_path

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end
