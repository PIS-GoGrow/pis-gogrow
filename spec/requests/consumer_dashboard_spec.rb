# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Consumer dashboard", type: :request do
  fixtures :benefit_configurations, :benefits

  def consumer_user
    company = Company.create!(name: "GoGrow", address: "18 de Julio 1006")
    user = User.create!(
      email: "consumer-menu@gmail.com",
      name: "Sofía",
      password: "password123456"
    )

    consumer = Consumer.create!(
      user:,
      company:,
      address: "Ellauri 1234"
    )

    consumer.saved_addresses.create!(
      name: "Casa",
      street: "Ellauri 1234"
    )

    consumer.benefits.create!(
      description: "Viandas mensuales",
      amount: 20,
      percentage: 50,
      due_date: Date.current + 3.days,
      benefit_configuration: benefit_configurations(:monthly)
    )

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
    travel_to(Time.zone.local(2026, 9, 14, 10))
    Order.destroy_all
    Schedule.delete_all
    user = consumer_user
    schedule = create_schedule
    sign_in_as_consumer(user)

    get dashboard_path

    expect(response).to have_http_status(:success)
    expect(inertia).to render_component("consumer/dashboard/index")
    expect(inertia).to have_props { |props|
      props[:schedules].one? &&
        props[:schedules].first[:id] == schedule.id &&
        props.dig(:benefit, :percentage) == 50
    }
  end
  it "renders the cart with its server props" do
      travel_to(Time.zone.local(2026, 9, 14, 10))
      Order.destroy_all
      Schedule.delete_all
      user = consumer_user
      schedule = create_schedule
      sign_in_as_consumer(user)

      get dashboard_cart_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("consumer/dashboard/cart")
      expect(inertia).to have_props { |props|
        props.dig(:benefit, :percentage) == 50 &&
          props[:addresses].pluck(:label) == [ "Oficina", "Casa" ]
      }
    end

  # La tarjeta "Tu consumo" muestra el mes contra el tope mensual: no hay tope
  # semanal en los requisitos, y dividir el mensual entre 4 daba 0 con K < 4.
  it "reports the monthly allowance using delivery dates" do
    travel_to(Time.zone.local(2026, 9, 14, 10))
    Order.destroy_all
    Schedule.delete_all
    user = consumer_user
    schedule = create_schedule
    Order.create!(consumer: user.consumer, schedule:, amount: 2, price: 600, discounted_price: 300, address: user.consumer.address, delivery_method: :home)
         .apply_benefit! user.consumer.benefits.first, 2
    next_week_schedule = Schedule.create!(menu: schedule.menu, date: schedule.date + 1.week, amount: 5)
    Order.create!(consumer: user.consumer, schedule: next_week_schedule, amount: 3, price: 900, discounted_price: 450, address: user.consumer.address, delivery_method: :home)
         .apply_benefit! user.consumer.benefits.first, 3
    sign_in_as_consumer(user)

    get dashboard_path

    expect(user.consumer.benefits.first.amount).to eq(20)
    expect(inertia).to have_props(
      benefit: {
        percentage: 50,
        monthly_limit: 20,
        monthly_used: 5,
        monthly_remaining: 15,
        specials: []
      }
    )
  end

  describe "shared notifications" do
    let!(:notification_configuration) do
      Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
        configuration.roles = %w[consumer]
      end
    end

    def create_notification(user:, notifiable:, role: "consumer", description_data:)
      Notification.create!(
        notification_configuration:,
        user:,
        role:,
        event: "order_confirmation",
        requires_action: false,
        notifiable:,
        description_data:
      )
    end

    it "shares only active notifications for the current user and active role" do
      user = consumer_user

      # El mismo usuario también tiene rol provider para poder comprobar
      # que las notificaciones de otro rol no aparecen en sesión consumer.
      provider = Provider.create!(user:)
      user.reload

      visible = create_notification(
        user:,
        notifiable: user,
        description_data: { date: "12/12", provider: "Visible" }
      )

      closed = create_notification(
        user:,
        notifiable: user.consumer,
        description_data: { date: "", provider: "Closed" }
      )
      closed.update_column(:closed_at, Time.current)

      create_notification(
        user:,
        notifiable: provider,
        role: "provider",
        description_data: { date: "", provider: "Wrong role" }
      )

      other_user = User.create!(
        email: "other-dashboard-notifications@gmail.com",
        name: "Martín",
        password: "password123456"
      )
      other_company = Company.create!(
        name: "Otra empresa",
        address: "Colonia 1234"
      )
      other_consumer = Consumer.create!(
        user: other_user,
        company: other_company,
        address: "Ejido 1234"
      )
      other_user.reload

      create_notification(
        user: other_user,
        notifiable: other_consumer,
        description_data: { date: "", provider: "Other user" }
      )

      sign_in_as_consumer(user)

      get dashboard_path

      notifications = inertia.props[:notifications]

      expect(notifications.pluck("id")).to eq([ visible.id ])
      expect(notifications.first).to include(
        "description" => "Tu pedido del 12/12 fue confirmado por Visible.",
        "requires_action" => false
      )
    end
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
  describe "GET /menu-semanal — consulting the menu by date (IBP-003)" do
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
      Order.destroy_all
      Schedule.delete_all
    end

    def publish(menu, date, amount: 5)
      Schedule.create!(menu:, date:, amount:)
    end

    def order_for(schedule, quantity, consumer: consumers(:one), benefit: nil)
      order = Order.create!(
        consumer:,
        schedule:,
        amount: quantity,
        price: schedule.menu.price * quantity,
        address: consumer.company.address,
        delivery_method: :office
      )
      order.apply_benefit! benefit, quantity if benefit

      order
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

    # IBP-087: el empleado no ve los platos del proveedor que cerró ese día, y
    # sabe por qué: el cierre viaja aparte, con el motivo y el período.
    describe "provider closures" do
      def close(owner, from, to = from, reason: "Vacaciones")
        owner.closures.create!(starts_on: from, ends_on: to, reason:)
      end

      def schedule_ids
        inertia.props[:schedules].pluck(:id)
      end

      it "leaves out the dishes of the provider that closed that day and keeps the rest" do
        closed_dish = publish(menus(:milanesa), monday)
        open_dish = publish(menus(:sorrentinos), monday)
        close(providers(:tuviandita), monday, monday + 1)
        sign_in users(:one)

        get dashboard_path

        expect(schedule_ids).to eq([ open_dish.id ])
        expect(schedule_ids).not_to include(closed_dish.id)
      end

      it "leaves out only the closed days and not the rest of the week" do
        before_closure = publish(menus(:milanesa), monday)
        on_closure = publish(menus(:milanesa), monday + 1)
        after_closure = publish(menus(:milanesa), monday + 2)
        close(providers(:tuviandita), monday + 1)
        sign_in users(:one)

        get dashboard_path

        expect(schedule_ids).to contain_exactly(before_closure.id, after_closure.id)
        expect(schedule_ids).not_to include(on_closure.id)
      end

      it "shows the dish again once the closure is deleted" do
        dish = publish(menus(:milanesa), monday)
        close(providers(:tuviandita), monday).destroy!
        sign_in users(:one)

        get dashboard_path

        expect(schedule_ids).to eq([ dish.id ])
      end

      it "sends the closures of every provider with the provider, the reason and the period" do
        close(providers(:tuviandita), Date.new(2026, 9, 21), Date.new(2026, 10, 2), reason: "Vacaciones")
        close(providers(:endulzate), Date.new(2026, 9, 14), reason: "Feriado")
        sign_in users(:one)

        get dashboard_path

        expect(inertia.props[:closures]).to contain_exactly(
          a_hash_including(provider_name: users(:provider_user).name, reason: "Vacaciones",
                           starts_on: "2026-09-21", ends_on: "2026-10-02", period: "21/09/26 al 02/10/26"),
          a_hash_including(provider_name: users(:other_provider_user).name, reason: "Feriado",
                           starts_on: "2026-09-14", ends_on: "2026-09-14", period: "14/09/26")
        )
      end

      it "does not send closures that already ended" do
        close(providers(:tuviandita), monday, monday + 1)
        travel_to Time.zone.local(2026, 9, 16, 10)
        sign_in users(:one)

        get dashboard_path

        expect(inertia.props[:closures]).to eq([])
      end

      it "sends an empty list when nobody closed" do
        sign_in users(:one)

        get dashboard_path

        expect(inertia.props[:closures]).to eq([])
      end

      it "loads the closures with a fixed number of queries, however many dishes there are" do
        3.times { |day| publish(menus(:milanesa), monday + day) }
        publish(menus(:sorrentinos), monday)
        close(providers(:tuviandita), monday + 4)
        sign_in users(:one)
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("provider_closures") }

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get dashboard_path }

        expect(queries.size).to be <= 2
      end
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

      get dashboard_cart_path

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
      benefit = Benefit.create!(consumer: consumers(:other), amount: 5, percentage: 50, due_date: 1.month.from_now, benefit_configuration: benefit_configurations(:monthly))
      order_for(schedule, 3, consumer: consumers(:other), benefit:)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:benefit]).to include(monthly_used: 0)
    end
  end

  # Historia: "Como EMPLEADO, quiero consultar la información relevante de cada
  # plato, para tomar una decisión informada."
  #
  # Acá se verifica que el server entregue cada dato, y que lo ausente viaje
  # como ausente. Cómo se pinta eso en pantalla —y qué se muestra cuando falta—
  # se cubre en app/javascript/pages/consumer/dashboard/dish-detail.test.tsx.
  describe "GET /menu-semanal — información de cada plato" do
    fixtures :users, :consumers, :companies, :providers, :menus, :reviews, :benefit_configurations, :benefits

    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:monday) { Date.current.beginning_of_week(:monday) }

    before do
      Order.destroy_all
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
      expect(reviews.first).to include(rating: 5, created_at: "2026-09-20", author: nil)
      expect(reviews.pluck(:description)).not_to include("Estaban bien, nada del otro mundo")
    end

    # IBP-012, criterio 1 y 2: el promedio sale de las cinco valoraciones válidas
    # ((3+4+4+5+5)/5 = 4.2) y el conteo las abarca a todas, aunque solo se envíen
    # las cuatro más recientes.
    it "exposes the average rating and the number of ratings" do
      publish(menus(:sorrentinos), monday)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first[:menu]).to include(
        rating_average: 4.2,
        rating_count: 5
      )
    end

    # IBP-012, criterio 4: sin reseñas, la lista viaja vacía y sin promedio.
    it "exposes an empty review list for a dish nobody reviewed" do
      publish(menus(:milanesa), monday)
      sign_in users(:one)

      get dashboard_path

      menu = inertia.props[:schedules].first[:menu]
      expect(menu[:reviews]).to eq([])
      expect(menu).to include(rating_average: nil, rating_count: 0)
    end

    # IBP-012, criterio 2: una reseña sin puntaje no es una valoración válida, así
    # que no cuenta para el promedio ni viaja en la lista de reseñas publicadas.
    it "ignores reviews that have no rating" do
      menus(:milanesa).update_column(:description, nil)
      publish(menus(:milanesa), monday)
      publish(menus(:office_menu), monday)
      sign_in users(:one)

      get dashboard_path

      by_name = inertia.props[:schedules].map { |s| s[:menu] }.index_by { |m| m[:name] }
      expect(by_name.fetch("Milanesa con papas fritas")[:description]).to be_nil

      office_menu = by_name.fetch("Ensalada de quinoa")
      expect(office_menu[:reviews]).to eq([])
      expect(office_menu).to include(rating_average: nil, rating_count: 0)
    end

    # IBP-012, criterio 3: la reseña identifica al autor por su primer nombre, sin
    # exponer el nombre completo.
    it "exposes only the author's first name, never their full name" do
      menu = menus(:milanesa)
      Review.create!(menu:, consumer: consumers(:one), rating: 5, description: "Riquísimo")
      publish(menu, monday)
      sign_in users(:one)

      get dashboard_path

      review = inertia.props[:schedules].first.dig(:menu, :reviews).first
      expect(review[:author]).to eq("Test")
      expect(review[:author]).not_to eq(users(:one).name)
    end

    it "sends the option groups of a dish that has none as an empty list" do
      publish(menus(:milanesa), monday)
      sign_in users(:one)

      get dashboard_path

      expect(inertia.props[:schedules].first[:menu]).to include(option_groups: [])
    end


    # Criterio 2: el cupo subsidiado se cuenta por mes de entrega. Lo que se fija
    # acá es esa regla; que el mismo número se aplique a los días de la semana
    # que ya caen en el mes siguiente es un defecto, y está anotado como
    # TODO(integración) en el system spec de la historia.
    it "counts the monthly quota by delivery date inside the current month" do
      this_month = publish(menus(:milanesa), monday, amount: 30)
      next_month = publish(menus(:sorrentinos), Date.new(2026, 10, 1), amount: 30)
      benefit = benefits(:monthly)
      benefit.update!(due_date: 1.month.from_now, amount: 20, percentage: 50)
      [ [ this_month, 3 ], [ next_month, 7 ] ].each do |schedule, quantity|
        order = Order.create!(
          consumer: consumers(:one), schedule:, amount: quantity,
          price: schedule.menu.price * quantity,
          address: consumers(:one).company.address, delivery_method: :office,
          selected_options: selection_for(schedule.menu)
        )
        order.apply_benefit! benefit, quantity
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

  describe "GET /menu-semanal during weekend" do
    let(:consumer_user_record) { consumer_user }
    let(:saturday) { Time.zone.local(2026, 10, 3, 10, 0, 0) }
    let(:next_monday) { Date.new(2026, 10, 5) }
    let(:next_friday) { Date.new(2026, 10, 9) }

    before do
      Order.destroy_all
      Schedule.delete_all
    end

    it "shows next week's menu and date range when accessed on a Saturday" do
      travel_to(saturday) do
        provider_user = User.create!(email: "provider-weekend@gmail.com", name: "Viandas FinDe", password: "password123456")
        provider = Provider.create!(user: provider_user)
        menu = Menu.create!(provider:, name: "Wok de vegetales", description: "Plato de prueba", price: 300)

        # Schedule for this past Friday (should not be included)
        Schedule.create!(menu:, date: Date.new(2026, 10, 2), amount: 10)
        # Schedule for next Monday (should be included)
        next_week_schedule = Schedule.create!(menu:, date: next_monday, amount: 10)

        sign_in_as_consumer(consumer_user_record)
        get dashboard_path

        expect(response).to have_http_status(:success)
        expect(inertia).to render_component("consumer/dashboard/index")
        expect(inertia.props[:week]).to include(
          start_date: next_monday.iso8601,
          end_date: next_friday.iso8601
        )
        expect(inertia.props[:week][:days].pluck(:date)).to eq(
          (next_monday..next_friday).map(&:iso8601)
        )
        expect(inertia.props[:schedules].map { |s| s[:id] }).to eq([ next_week_schedule.id ])
      end
    end

    it "shows next week's menu when accessed on a Sunday" do
      sunday = Time.zone.local(2026, 10, 4, 15, 0, 0)
      travel_to(sunday) do
        sign_in_as_consumer(consumer_user_record)
        get dashboard_path

        expect(inertia.props[:week]).to include(
          start_date: next_monday.iso8601,
          end_date: next_friday.iso8601
        )
      end
    end
  end

  describe "GET /menu-semanal/confirmacion" do
    let(:user) { consumer_user }
    let(:consumer) { user.consumer }

    it "redirects visitors to the sign in page" do
      get dashboard_confirmation_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects users with another role to root_path" do
      provider_user = User.create!(email: "prov-conf@gmail.com", name: "Prov", password: "password123456")
      Provider.create!(user: provider_user)
      session = provider_user.sessions.create!(role: :provider)
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)

      get dashboard_confirmation_path
      expect(response).to redirect_to(root_path)
    end

    it "renders the confirmation page with order details and totals" do
      provider_user = User.create!(email: "prov-conf-2@gmail.com", name: "La Cocina", password: "password123456")
      provider = Provider.create!(user: provider_user)
      menu = Menu.create!(provider:, name: "Tarta Pascualina", description: "Plato de prueba", price: 250)
      schedule = Schedule.create!(menu:, date: Date.current, amount: 10)
      order = Order.create!(
        consumer:,
        schedule:,
        amount: 2,
        price: 500,
        discounted_price: 250,
        address: consumer.company.address,
        delivery_method: :office,
        status: :pending
      )

      sign_in_as_consumer(user)
      get dashboard_confirmation_path(confirmed_order_ids: [ order.id ])

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("consumer/dashboard/confirmation")
      expect(inertia).to have_props(
        total: 250.0,
        orders: [
          {
            id: order.id,
            date: schedule.date.iso8601,
            address: consumer.company.address,
            delivery_method: "office",
            provider_name: "La Cocina",
            name: "Tarta Pascualina",
            quantity: 2,
            discounted_price: 250.0
          }
        ]
      )
    end

    it "redirects to the dashboard when order IDs do not belong to the signed-in consumer" do
      other_user = User.create!(email: "other-conf@gmail.com", name: "Otro", password: "password123456")
      other_consumer = Consumer.create!(user: other_user, company: consumer.company, address: "Dir 123")
      provider_user = User.create!(email: "prov-conf-3@gmail.com", name: "La Cocina", password: "password123456")
      provider = Provider.create!(user: provider_user)
      menu = Menu.create!(provider:, name: "Guiso de lentejas", description: "Plato de prueba", price: 250)
      schedule = Schedule.create!(menu:, date: Date.current, amount: 10)
      other_order = Order.create!(
        consumer: other_consumer,
        schedule:,
        amount: 1,
        price: 250,
        discounted_price: 250,
        address: other_consumer.address,
        delivery_method: :home,
        status: :pending
      )

      sign_in_as_consumer(user)
      get dashboard_confirmation_path(confirmed_order_ids: [ other_order.id ])

      expect(response).to redirect_to(dashboard_path)
      expect(response.body).not_to include(other_order.address)
    end

    it "redirects to the dashboard without confirmed order IDs" do
      sign_in_as_consumer(user)

      get dashboard_confirmation_path

      expect(response).to redirect_to(dashboard_path)
    end

    it "redirects to the dashboard when confirmed_order_ids is empty or an empty string" do
      sign_in_as_consumer(user)

      get dashboard_confirmation_path(confirmed_order_ids: [])
      expect(response).to redirect_to(dashboard_path)

      get dashboard_confirmation_path(confirmed_order_ids: "")
      expect(response).to redirect_to(dashboard_path)
    end

    it "redirects to the dashboard when confirmed_order_ids contains non-numeric strings or negative numbers" do
      sign_in_as_consumer(user)

      get dashboard_confirmation_path(confirmed_order_ids: [ "invalido", "null", "<script>" ])
      expect(response).to redirect_to(dashboard_path)

      get dashboard_confirmation_path(confirmed_order_ids: [ -1, 0 ])
      expect(response).to redirect_to(dashboard_path)
    end

    it "redirects to the dashboard when mixing a valid own order ID with an unauthorized order ID" do
      provider_user = User.create!(email: "prov-mix@gmail.com", name: "La Cocina", password: "password123456")
      provider = Provider.create!(user: provider_user)
      menu = Menu.create!(provider:, name: "Tarta Mixta", description: "Plato de prueba", price: 250)
      schedule = Schedule.create!(menu:, date: Date.current, amount: 10)
      own_order = Order.create!(
        consumer:,
        schedule:,
        amount: 1,
        price: 250,
        discounted_price: 250,
        address: consumer.company.address,
        delivery_method: :office,
        status: :pending
      )

      other_user = User.create!(email: "other-mix@gmail.com", name: "Otro Mix", password: "password123456")
      other_consumer = Consumer.create!(user: other_user, company: consumer.company, address: "Dir 456")
      other_order = Order.create!(
        consumer: other_consumer,
        schedule:,
        amount: 1,
        price: 250,
        discounted_price: 250,
        address: other_consumer.address,
        delivery_method: :home,
        status: :pending
      )

      sign_in_as_consumer(user)
      get dashboard_confirmation_path(confirmed_order_ids: [ own_order.id, other_order.id ])

      expect(response).to redirect_to(dashboard_path)
      expect(response.body).not_to include(own_order.address)
      expect(response.body).not_to include(other_order.address)
    end

    it "redirects admin users to root_path" do
      sign_in users(:admin), role: :admin

      get dashboard_confirmation_path
      expect(response).to redirect_to(root_path)
    end

    it "preserves database integrity and does not create or alter orders on GET request" do
      sign_in_as_consumer(user)

      expect {
        get dashboard_confirmation_path(confirmed_order_ids: [ 999_999 ])
      }.not_to change(Order, :count)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  # IBP-037: el carrito necesita los subsidios especiales vigentes para mostrar
  # el precio con base + especial antes de confirmar.
  describe "GET /menu-semanal — subsidios especiales" do
    around do |example|
      travel_to(Time.zone.local(2026, 9, 14, 10)) { example.run }
    end

    let(:consumer) { consumers(:one) }

    before do
      consumer.benefits.destroy_all
      consumer.benefits.create!(
        benefit_configuration: benefit_configurations(:monthly), percentage: 50, amount: 20, due_date: Date.new(2026, 9, 30)
      )
      sign_in users(:one)
    end

    it "exposes the special subsidies in force with their uses left" do
      gift = consumer.benefits.create!(
        benefit_configuration: benefit_configurations(:gift), description: "Premio", percentage: 30, amount: 2, due_date: Date.new(2026, 9, 19)
      )
      seniority = consumer.benefits.create!(
        benefit_configuration: benefit_configurations(:seniority), description: "Antigüedad", percentage: 10
      )
      OrderBenefit.create!(order: orders(:upcoming_pending_future), benefit: gift, benefit_used: 1)

      get dashboard_path

      expect(inertia.props[:benefit]).to include(
        percentage: 50,
        specials: [
          { id: gift.id, name: "Premio", percentage: 30, remaining: 1, due_date: "2026-09-19" },
          { id: seniority.id, name: "Antigüedad", percentage: 10, remaining: nil, due_date: nil }
        ]
      )
    end

    it "leaves out expired and deactivated special subsidies" do
      consumer.benefits.create!(benefit_configuration: benefit_configurations(:gift), percentage: 30, status: :expired)
      consumer.benefits.create!(benefit_configuration: benefit_configurations(:seniority), percentage: 10)
      benefit_configurations(:seniority).update!(deactivated_at: Time.current)

      get dashboard_path

      expect(inertia.props[:benefit][:specials]).to eq([])
    end
  end
end
