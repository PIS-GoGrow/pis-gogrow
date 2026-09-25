# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer dashboard", type: :request do
  def consumer_user
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    user = User.create!(email: "consumer-menu@gmail.com", name: "Sofía", password: "password123456")
    Consumer.create!(user:, company:, address: "Ellauri 1234")
    user
  end

  def sign_in_as_consumer(user)
    session = user.sessions.create!(role: :consumer)
    cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
  end

  def create_schedule
    provider_user = User.create!(email: "provider-menu@gmail.com", name: "Endulzate by Noe", password: "password123456")
    provider = Provider.create!(user: provider_user)
    menu = Menu.create!(provider:, name: "Sorrentinos", description: "Jamón y queso", price: 300)
    Schedule.create!(menu:, date: Date.current.beginning_of_week(:monday), amount: 5)
  end

  it "uses the weekly menu as the landing page for a remembered consumer session" do
    user = consumer_user
    sign_in_as_consumer(user)

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end

  it "renders the protected weekly menu with its server props" do
    Order.delete_all
    Schedule.delete_all
    user = consumer_user
    schedule = create_schedule
    Benefit.create!(consumer: user.consumer, amount: 5, percentage: 50, due_date: 1.month.from_now)
    sign_in_as_consumer(user)

    get dashboard_path

    expect(response).to have_http_status(:success)
    expect(inertia).to render_component("consumer/dashboard/index")
    expect(inertia).to have_props { |props|
      props[:schedules].one? &&
        props[:schedules].first[:id] == schedule.id &&
        props.dig(:benefit, :percentage) == 50 &&
        props[:addresses].pluck(:label) == [ "Oficina", "Casa" ]
    }
  end

  it "reports the five meal weekly allowance using delivery dates" do
    Order.delete_all
    Schedule.delete_all
    user = consumer_user
    schedule = create_schedule
    benefit = Benefit.create!(consumer: user.consumer, amount: 20, percentage: 50, due_date: 1.month.from_now)
    Order.create!(consumer: user.consumer, schedule:, amount: 2, price: 600, discounted_price: 300, address: user.consumer.address, delivery_method: :home)

    next_week_schedule = Schedule.create!(menu: schedule.menu, date: schedule.date + 1.week, amount: 5)
    Order.create!(consumer: user.consumer, schedule: next_week_schedule, amount: 3, price: 900, discounted_price: 450, address: user.consumer.address, delivery_method: :home)
    sign_in_as_consumer(user)

    get dashboard_path

    expect(benefit.amount).to eq(20)
    expect(inertia).to have_props(
      benefit: {
        limit: 5,
        used: 2,
        percentage: 50,
        monthly_limit: 20,
        monthly_used: 5,
        monthly_remaining: 15
      }
    )
  end

  # IBP-003 — "Como EMPLEADO, quiero consultar en un único lugar el menú
  # disponible para una fecha, incluyendo las opciones de todos los proveedores,
  # para elegir qué comida pedir."
  #
  # La pantalla que el empleado realmente alcanza para esto es /dashboard: es a
  # donde apunta "Menú del día" en el sidebar. /menus implementa la misma
  # historia pero quedó huérfana (ningún enlace de la app la alcanza) — ver
  # docs/reports/defects/ en el repo de testing.
  #
  # El día concreto se elige en el browser sobre la semana que devuelve el
  # server, así que acá se verifica la ventana lunes–viernes y la forma de los
  # props; el filtrado por día se cubre en spec/system/consumer.
  describe "GET /dashboard — consulting the menu by date (IBP-003)" do
    fixtures :users, :consumers, :companies, :providers, :menus

    # Un lunes fijo: la pantalla arma la semana desde Date.current, así que sin
    # congelar el reloj el spec cambia de significado según el día que corra.
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:monday) { Date.current.beginning_of_week(:monday) }

    before do
      # Los fixtures publican platos con fechas relativas a la fecha real, que
      # bajo travel_to caen en cualquier lado. Se limpia para que cada ejemplo
      # declare exactamente lo que espera ver.
      Order.delete_all
      Schedule.delete_all
    end

    def publish(menu, date, amount: 5)
      Schedule.create!(menu:, date:, amount:)
    end

    def order_for(schedule, quantity, consumer: consumers(:one))
      Order.create!(
        consumer:,
        schedule:,
        amount: quantity,
        price: schedule.menu.price * quantity,
        address: consumer.company.address,
        delivery_method: :office
      )
    end

    # Criterio 1: los platos de todos los proveedores, en un mismo lugar.
    it "gathers dishes from different providers on the same date" do
      publish(menus(:milanesa), monday)
      publish(menus(:sorrentinos), monday)
      sign_in users(:one)

      get dashboard_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("consumer/dashboard/index")

      on_monday = inertia.props[:schedules].select { |s| s[:date] == monday.iso8601 }
      expect(on_monday.map { |s| s.dig(:menu, :name) })
        .to contain_exactly("Milanesa con papas fritas", "Sorrentinos artesanales")
      expect(on_monday.map { |s| s.dig(:menu, :provider_name) })
        .to contain_exactly(users(:provider_user).name, users(:other_provider_user).name)
    end

    # Criterio 2: solo opciones de la fecha seleccionada. Del lado del server eso
    # es la ventana lunes–viernes; se prueban los dos bordes (N y N+1).
    it "publishes the monday to friday week and leaves out what falls outside it" do
      publish(menus(:milanesa), monday)
      publish(menus(:milanesa), monday + 4)
      previous_sunday = publish(menus(:milanesa), monday - 1)
      next_saturday = publish(menus(:milanesa), monday + 5)
      sign_in users(:one)

      get dashboard_path

      dates = inertia.props[:schedules].pluck(:date)
      expect(dates).to contain_exactly(monday.iso8601, (monday + 4).iso8601)
      expect(inertia.props[:schedules].pluck(:id))
        .not_to include(previous_sunday.id, next_saturday.id)
      expect(inertia.props.dig(:week, :start_date)).to eq(monday.iso8601)
      expect(inertia.props.dig(:week, :end_date)).to eq((monday + 4).iso8601)
    end

    # Criterio 3, primera mitad: el agotado se identifica. El prop sold_out es
    # lo único de lo que dispone la pantalla para marcarlo, y sale de descontar
    # los pedidos vivos del cupo — no del cupo bruto.
    it "does not mark a dish as sold out while quota remains" do
      schedule = publish(menus(:milanesa), monday, amount: 2)
      order_for(schedule, 1)
      sign_in users(:one)

      get dashboard_path

      dish = inertia.props[:schedules].first
      expect(dish).to include(sold_out: false, remaining: 1)
    end

    it "marks a dish sold out once its whole quota is ordered" do
      sold_out_dish = publish(menus(:milanesa), monday, amount: 2)
      available_dish = publish(menus(:sorrentinos), monday, amount: 2)
      order_for(sold_out_dish, 2)
      sign_in users(:one)

      get dashboard_path

      by_id = inertia.props[:schedules].index_by { |s| s[:id] }
      expect(by_id.fetch(sold_out_dish.id)).to include(sold_out: true, remaining: 0)
      expect(by_id.fetch(available_dish.id)).to include(sold_out: false, remaining: 2)
    end

    it "does not count cancelled orders against the quota" do
      schedule = publish(menus(:milanesa), monday, amount: 1)
      order_for(schedule, 1).update!(status: :cancelled)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first).to include(sold_out: false, remaining: 1)
    end

    it "does not count rejected orders against the quota" do
      schedule = publish(menus(:milanesa), monday, amount: 1)
      order_for(schedule, 1).update!(status: :rejected, rejection_reason: :out_of_stock)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first).to include(sold_out: false, remaining: 1)
    end

    it "filters out home address when the consumer does not have one registered" do
      consumers(:one).update!(address: nil)
      publish(menus(:milanesa), monday)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:addresses].pluck(:id)).to eq([ "office" ])
    end

    # Criterio 4: estado vacío. Del lado del server, la lista vacía sin error.
    it "responds with no dishes when nothing is published for the week" do
      publish(menus(:milanesa), monday - 1)
      sign_in users(:one)

      get dashboard_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("consumer/dashboard/index")
      expect(inertia.props[:schedules]).to be_empty
    end

    # Transversal — permisos. El caso de rol equivocado ya está cubierto arriba;
    # falta el visitante sin sesión, que es el otro borde del mismo límite.
    it "redirects a visitor with no session to the sign in page" do
      publish(menus(:milanesa), monday)

      get dashboard_path

      expect(response).to redirect_to(sign_in_path)
    end

    # Transversal — privacidad entre pares: el menú es común a todos los
    # empleados, pero los contadores del beneficio son personales.
    it "does not count another employee orders in the own benefit" do
      schedule = publish(menus(:milanesa), monday, amount: 10)
      order_for(schedule, 3, consumer: consumers(:other))
      Benefit.create!(consumer: consumers(:one), amount: 5, percentage: 50, due_date: 1.month.from_now)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:benefit]).to include(used: 0, monthly_used: 0)
    end
  end

  # Historia: "Como EMPLEADO, quiero consultar la información relevante de cada
  # plato, para tomar una decisión informada."
  #
  # Acá se verifica que el server entregue cada dato, y que lo ausente viaje
  # como ausente. Cómo se pinta eso en pantalla —y qué se muestra cuando falta—
  # se cubre en app/javascript/pages/consumer/dashboard/dish-detail.test.tsx.
  describe "GET /dashboard — información de cada plato" do
    fixtures :users, :consumers, :companies, :providers, :menus, :reviews

    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:monday) { Date.current.beginning_of_week(:monday) }

    before do
      Order.delete_all
      Schedule.delete_all
    end

    def publish(menu, date, amount: 5)
      Schedule.create!(menu:, date:, amount:)
    end

    # Criterio 1: los cinco datos que la historia enumera, en una sola respuesta.
    it "exposes the name, provider, price, description and availability of a dish" do
      publish(menus(:sorrentinos), monday, amount: 4)
      sign_in users(:one)

      get dashboard_path

      dish = inertia.props[:schedules].first
      expect(dish).to include(sold_out: false, remaining: 4)
      expect(dish[:menu]).to include(
        name: "Sorrentinos artesanales",
        provider_name: users(:other_provider_user).name,
        price: 320.0,
        description: "Pasta rellena a elección"
      )
    end

    # Criterio 1: las reseñas son parte de la información del plato, y hasta
    # ahora ningún spec las tocaba — no existían ni fixtures.
    it "exposes the four most recent reviews of a dish, newest first" do
      publish(menus(:sorrentinos), monday)
      sign_in users(:one)

      get dashboard_path

      reviews = inertia.props[:schedules].first.dig(:menu, :reviews)
      expect(reviews.pluck(:description)).to eq([
        "Mi plato fijo de los miércoles",
        "La salsa filetto es la mejor",
        "Llegaron calientes",
        "Porción generosa"
      ])
      expect(reviews.first).to include(rating: 5, created_at: "2026-09-20")
      expect(reviews.pluck(:description)).not_to include("Estaban bien, nada del otro mundo")
    end

    # Criterio 3: sin reseñas, la lista viaja vacía. Que la pantalla invente una
    # a partir de esto es un defecto aparte, no algo que el server insinúe.
    it "exposes an empty review list for a dish nobody reviewed" do
      publish(menus(:milanesa), monday)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first.dig(:menu, :reviews)).to eq([])
    end

    # Criterio 3: un dato opcional ausente viaja como ausente, no como texto
    # inventado ni como cadena vacía que la pantalla pueda confundir con un dato.
    it "sends optional data that was never filled in as null" do
      menus(:milanesa).update!(description: nil)
      publish(menus(:milanesa), monday)
      publish(menus(:office_menu), monday)
      sign_in users(:one)

      get dashboard_path

      by_name = inertia.props[:schedules].map { |s| s[:menu] }.index_by { |m| m[:name] }
      expect(by_name.fetch("Milanesa con papas fritas")[:description]).to be_nil

      review = by_name.fetch("Ensalada de quinoa")[:reviews].first
      expect(review).to include(description: nil, rating: nil)
    end

    it "sends the toppings of a dish that has none as an empty list" do
      publish(menus(:milanesa), monday)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first[:menu]).to include(fillings: [], sauces: [])
    end

    # Criterio 2: el cupo subsidiado se cuenta por mes de entrega. Lo que se fija
    # acá es esa regla; que el mismo número se aplique a los días de la semana
    # que ya caen en el mes siguiente es un defecto, y está anotado como
    # TODO(integración) en el system spec de la historia.
    it "counts the monthly quota by delivery date inside the current month" do
      this_month = publish(menus(:milanesa), monday, amount: 30)
      next_month = publish(menus(:sorrentinos), Date.new(2026, 10, 1), amount: 30)
      Benefit.create!(consumer: consumers(:one), amount: 20, percentage: 50, due_date: 1.month.from_now)
      [ [ this_month, 3 ], [ next_month, 7 ] ].each do |schedule, quantity|
        Order.create!(
          consumer: consumers(:one), schedule:, amount: quantity,
          price: schedule.menu.price * quantity,
          address: consumers(:one).company.address, delivery_method: :office
        )
      end
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:benefit]).to include(monthly_used: 3, monthly_remaining: 17)
    end
  end

  it "rejects a session with a different role" do
    provider_user = User.create!(email: "provider-role@gmail.com", name: "Provider", password: "password123456")
    Provider.create!(user: provider_user)
    session = provider_user.sessions.create!(role: :provider)
    cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

    get dashboard_path

    expect(response).to redirect_to(root_path)
  end

  it "selects the consumer role from the Google sign-in cookie" do
    user = consumer_user
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "consumer-menu-google-uid",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: user.email,
        name: user.name,
        image: "https://example.com/avatar.png"
      )
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    cookies[:accessing_role] = AuthenticationHelpers.signed_cookie(:accessing_role, "consumer")

    get "/auth/google_oauth2/callback"

    expect(response).to redirect_to(root_path)
    expect(user.sessions.last).to be_consumer
    expect(cookies[:session_token]).to be_present
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
