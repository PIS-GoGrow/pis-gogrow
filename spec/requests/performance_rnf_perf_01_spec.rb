# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RNF-PERF-01 Performance Benchmark", type: :request do
  fixtures :all

  let(:user) { users(:one) }

  before do
    sign_in user, role: :consumer
  end

  def measure_operation(count = 5)
    times = []
    # Warm-up
    yield

    count.times do
      duration = nil
      subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do |_name, start, finish, _id, _payload|
        duration = (finish - start) * 1000.0
      end

      yield
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(response).to have_http_status(:success)
      times << (duration || 0.0)
    end

    times
  end

  describe "Medición de tiempo de ejecución del controlador y consultas" do
    it "mide los tiempos de las 4 operaciones" do
      schedule = schedules(:today)

      results = {}

      # 1. Consultar menú de una fecha / semanal
      results["1. Consultar menú semanal"] = measure_operation do
        get "/menu-semanal"
      end

      # 2. Visualizar detalle de plato
      results["2. Visualizar detalle de plato"] = measure_operation do
        get "/menu-semanal/platos/#{schedule.id}"
      end

      # 3. Consultar pedidos propios
      results["3. Consultar pedidos propios"] = measure_operation do
        get "/pedidos"
      end

      # 4. Consultar deuda y estado de pagos
      results["4. Consultar deuda y pagos"] = measure_operation do
        get "/payments"
      end

      puts "\n" + "=" * 70
      puts "Operación                           | Mínimo     | Máximo     | Promedio  "
      puts "-" * 70

      results.each do |op_name, times|
        min = times.min
        max = times.max
        avg = times.sum / times.size

        puts sprintf("%-35s | %7.2f ms | %7.2f ms | %7.2f ms", op_name, min, max, avg)
        expect(max).to be <= 2000.0
      end

      puts "=" * 70
    end
  end
end
