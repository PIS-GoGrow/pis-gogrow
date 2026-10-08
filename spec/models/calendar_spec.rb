# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  # Calendario de referencia (octubre 2026):
  #
  #   Lu  Ma  Mi  Ju  Vi  Sa  Do
  #   28  29  30   1   2   3   4   (viernes 2 = hoy en la mayoría de los ejemplos)
  #    5   6   7   8   9  10  11
  #   12  13  14  15  16  17  18
  #
  # Semana "esta": lunes 5/10 a domingo 11/10.

  def calendar_on(today)
    described_class.new(today: today)
  end

  describe "#initialize" do
    it "usa Date.current por defecto" do
      travel_to(Time.zone.local(2026, 10, 7, 12)) do
        expect(described_class.new.allowed_order_dates)
          .to eq(Date.new(2026, 10, 7)..Date.new(2026, 10, 9))
      end
    end
  end

  describe "#schedule_week_range" do
    context "cuando hoy es un día de semana" do
      {
        "lunes" => [ Date.new(2026, 10, 5), Date.new(2026, 10, 5)..Date.new(2026, 10, 9) ],
        "martes" => [ Date.new(2026, 10, 6), Date.new(2026, 10, 5)..Date.new(2026, 10, 9) ],
        "miércoles" => [ Date.new(2026, 10, 7), Date.new(2026, 10, 5)..Date.new(2026, 10, 9) ],
        "jueves" => [ Date.new(2026, 10, 8), Date.new(2026, 10, 5)..Date.new(2026, 10, 9) ],
        "viernes" => [ Date.new(2026, 10, 9), Date.new(2026, 10, 5)..Date.new(2026, 10, 9) ]
      }.each do |weekday, (today, expected)|
        it "devuelve la semana actual si es #{weekday}" do
          expect(calendar_on(today).schedule_week_range).to eq(expected)
        end
      end
    end

    context "cuando hoy es fin de semana" do
      it "devuelve la semana que viene si es sábado" do
        expect(calendar_on(Date.new(2026, 10, 10)).schedule_week_range)
          .to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 16))
      end

      it "devuelve la semana que viene si es domingo" do
        expect(calendar_on(Date.new(2026, 10, 11)).schedule_week_range)
          .to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 16))
      end
    end

    it "cruza correctamente el cambio de mes" do
      # Sábado 31/10/2026 -> semana del 2 al 8 de noviembre
      expect(calendar_on(Date.new(2026, 10, 31)).schedule_week_range)
        .to eq(Date.new(2026, 11, 2)..Date.new(2026, 11, 6))
    end

    it "cruza correctamente el cambio de año" do
      # Sábado 26/12/2026 -> semana del 28/12 al 3/1
      expect(calendar_on(Date.new(2026, 12, 26)).schedule_week_range)
        .to eq(Date.new(2026, 12, 28)..Date.new(2027, 1, 1))
    end
  end

  describe "#allowed_order_dates" do
    context "cuando hoy es un día de semana" do
      it "va desde hoy hasta el viernes si es lunes" do
        expect(calendar_on(Date.new(2026, 10, 5)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 5)..Date.new(2026, 10, 9))
      end

      it "va desde hoy hasta el viernes si es miércoles" do
        expect(calendar_on(Date.new(2026, 10, 7)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 7)..Date.new(2026, 10, 9))
      end

      it "va desde hoy hasta el viernes si es jueves" do
        expect(calendar_on(Date.new(2026, 10, 8)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 8)..Date.new(2026, 10, 9))
      end

      it "es solo hoy si es viernes" do
        expect(calendar_on(Date.new(2026, 10, 9)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 9)..Date.new(2026, 10, 9))
      end
    end

    context "cuando hoy es fin de semana" do
      it "es toda la semana que viene (lunes a viernes) si es sábado" do
        expect(calendar_on(Date.new(2026, 10, 10)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 16))
      end

      it "es toda la semana que viene (lunes a viernes) si es domingo" do
        expect(calendar_on(Date.new(2026, 10, 11)).allowed_order_dates)
          .to eq(Date.new(2026, 10, 12)..Date.new(2026, 10, 16))
      end
    end

    it "no incluye fechas pasadas" do
      today = Date.new(2026, 10, 7)
      expect(calendar_on(today).allowed_order_dates.min).to eq(today)
    end

    it "cruza el cambio de mes cuando la semana lo atraviesa" do
      # Miércoles 30/12/2026: el viernes es 1/1/2027
      expect(calendar_on(Date.new(2026, 12, 30)).allowed_order_dates)
        .to eq(Date.new(2026, 12, 30)..Date.new(2027, 1, 1))
    end
  end

  describe "#monthly_benefit_assignment" do
    {
      "viernes" => [ Date.new(2027, 4, 30), Date.new(2027, 4, 30) ],
      "sábado" => [ Date.new(2026, 10, 31), Date.new(2026, 10, 31) ],
      "domingo" => [ Date.new(2027, 1, 31), Date.new(2027, 1, 30) ],
      "lunes" => [ Date.new(2026, 11, 30), Date.new(2026, 11, 28) ],
      "martes" => [ Date.new(2027, 8, 31), Date.new(2027, 8, 28) ],
      "miércoles" => [ Date.new(2027, 3, 31), Date.new(2027, 3, 27) ],
      "jueves" => [ Date.new(2026, 12, 31), Date.new(2026, 12, 26) ]
    }.each do |weekday, (last_day_of_month, expected)|
      it "cuando el mes termina en #{weekday} devuelve #{expected}" do
        expect(calendar_on(last_day_of_month.beginning_of_month).monthly_benefit_assignment)
          .to eq(expected)
      end
    end

    it "es el último día del mes si este cae viernes" do
      calendar = calendar_on(Date.new(2027, 4, 12))
      expect(calendar.monthly_benefit_assignment).to eq(Date.new(2027, 4, 30))
    end

    it "es el último sábado del mes si el último día no es viernes" do
      calendar = calendar_on(Date.new(2026, 11, 3))
      expect(calendar.monthly_benefit_assignment).to eq(Date.new(2026, 11, 28))
    end

    it "maneja febrero en año bisiesto" do
      # Febrero 2028 termina el martes 29
      expect(calendar_on(Date.new(2028, 2, 10)).monthly_benefit_assignment)
        .to eq(Date.new(2028, 2, 26))
    end

    it "devuelve lo mismo para cualquier día del mismo mes" do
      results = (Date.new(2026, 10, 1)..Date.new(2026, 10, 31)).map do |day|
        calendar_on(day).monthly_benefit_assignment
      end

      expect(results.uniq).to eq([ Date.new(2026, 10, 31) ])
    end

    it "siempre cae en el mismo mes que hoy, en viernes o sábado" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 31)).each do |day|
        assignment = calendar_on(day).monthly_benefit_assignment

        expect(assignment.beginning_of_month).to eq(day.beginning_of_month), "falló para #{day}"
        expect(assignment.friday? || assignment.saturday?).to be(true), "falló para #{day}"
      end
    end

    describe "invariantes con allowed_order_dates" do
      let(:days_by_month) do
        (Date.new(2026, 1, 1)..Date.new(2030, 12, 31)).group_by(&:beginning_of_month)
      end

      it "si ya se puede pedir para el mes que viene, los beneficios ya fueron asignados" do
        days_by_month.each_value do |days|
          days.each do |today|
            calendar = calendar_on(today)
            next_month_start = today.next_month.beginning_of_month

            next unless calendar.allowed_order_dates.include?(next_month_start)

            expect(calendar.monthly_benefit_assignment).to be <= today,
                                                           "falló para #{today}"
          end
        end
      end

      it "es el mayor día del mes que cumple lo anterior" do
        days_by_month.each do |month_start, days|
          next_month_start = month_start.next_month

          days_ordering_next_month = days.select do |today|
            calendar_on(today).allowed_order_dates.include?(next_month_start)
          end

          # Hay meses en los que nunca se puede pedir para el día 1 del mes que viene
          # (por ejemplo, cuando el día 1 cae sábado o domingo).
          next if days_ordering_next_month.empty?

          expect(calendar_on(month_start).monthly_benefit_assignment)
            .to eq(days_ordering_next_month.min), "falló para #{month_start.strftime('%Y-%m')}"
        end
      end
    end
  end

  describe "#configuration_cutoff" do
    it "es el día anterior a la asignación de beneficios (mes que termina en sábado)" do
      expect(calendar_on(Date.new(2026, 10, 2)).configuration_cutoff).to eq(Date.new(2026, 10, 30))
    end

    it "es el día anterior a la asignación de beneficios (mes que termina en viernes)" do
      expect(calendar_on(Date.new(2027, 4, 2)).configuration_cutoff).to eq(Date.new(2027, 4, 29))
    end

    it "es el día anterior a la asignación de beneficios (mes que termina en domingo)" do
      expect(calendar_on(Date.new(2027, 1, 15)).configuration_cutoff).to eq(Date.new(2027, 1, 29))
    end

    it "es el mismo para cualquier día del mes" do
      results = (Date.new(2026, 11, 1)..Date.new(2026, 11, 30)).map do |day|
        calendar_on(day).configuration_cutoff
      end

      expect(results.uniq).to eq([ Date.new(2026, 11, 27) ])
    end

    it "siempre es estrictamente anterior a monthly_benefit_assignment" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 31)).each do |day|
        calendar = calendar_on(day)

        expect(calendar.configuration_cutoff).to eq(calendar.monthly_benefit_assignment - 1.day),
                                                 "falló para #{day}"
      end
    end
  end

  describe "#configurable_month" do
    context "mientras no se pasó configuration_cutoff" do
      it "es el mes que viene si es el primer día del mes" do
        expect(calendar_on(Date.new(2026, 10, 1)).configurable_month).to eq(Date.new(2026, 11, 1))
      end

      it "es el mes que viene si es hoy a mitad de mes" do
        expect(calendar_on(Date.new(2026, 10, 2)).configurable_month).to eq(Date.new(2026, 11, 1))
      end

      it "es el mes que viene el mismo día de configuration_cutoff" do
        expect(calendar_on(Date.new(2026, 10, 30)).configurable_month).to eq(Date.new(2026, 11, 1))
      end

      it "cruza el año si es diciembre" do
        expect(calendar_on(Date.new(2026, 12, 25)).configurable_month).to eq(Date.new(2027, 1, 1))
      end
    end

    context "una vez pasado configuration_cutoff" do
      it "es el otro mes el día de asignación de beneficios" do
        expect(calendar_on(Date.new(2026, 10, 31)).configurable_month).to eq(Date.new(2026, 12, 1))
      end

      it "es el otro mes si el último día es viernes y ya se asignaron los beneficios" do
        expect(calendar_on(Date.new(2027, 4, 30)).configurable_month).to eq(Date.new(2027, 6, 1))
      end

      it "es el otro mes entre la asignación y fin de mes" do
        # Enero 2027: asignación el sábado 30, hoy domingo 31
        expect(calendar_on(Date.new(2027, 1, 31)).configurable_month).to eq(Date.new(2027, 3, 1))
      end

      it "cruza el año si es diciembre" do
        # Diciembre 2026: asignación el sábado 26
        expect(calendar_on(Date.new(2026, 12, 26)).configurable_month).to eq(Date.new(2027, 2, 1))
      end
    end

    it "siempre devuelve el primer día de un mes" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 31)).each do |day|
        expect(calendar_on(day).configurable_month.day).to eq(1), "falló para #{day}"
      end
    end

    it "cambia de mes exactamente en monthly_benefit_assignment" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 1)).select { |d| d.day == 1 }.each do |month_start|
        calendar = calendar_on(month_start)
        cutoff = calendar.configuration_cutoff
        assignment = calendar.monthly_benefit_assignment

        expect(calendar_on(cutoff).configurable_month)
          .to eq(month_start.next_month), "falló en cutoff de #{month_start}"
        expect(calendar_on(assignment).configurable_month)
          .to eq(month_start.next_month.next_month), "falló en asignación de #{month_start}"
      end
    end
  end

  describe "#maximum_publish_date" do
    {
      "lunes" => [ Date.new(2026, 10, 5), Date.new(2026, 10, 16) ],
      "miércoles" => [ Date.new(2026, 10, 7), Date.new(2026, 10, 16) ],
      "viernes" => [ Date.new(2026, 10, 9), Date.new(2026, 10, 16) ]
    }.each do |weekday, (today, expected)|
      it "es el viernes de la semana siguiente si es #{weekday}" do
        expect(calendar_on(today).maximum_publish_date).to eq(expected)
      end
    end

    it "para sábado y domingo, define el criterio de fin de semana" do
      expect(calendar_on(Date.new(2026, 10, 10)).maximum_publish_date).to eq(Date.new(2026, 10, 16))
      expect(calendar_on(Date.new(2026, 10, 11)).maximum_publish_date).to eq(Date.new(2026, 10, 16))
    end

    it "cruza el cambio de mes y de año" do
      expect(calendar_on(Date.new(2026, 12, 30)).maximum_publish_date).to eq(Date.new(2027, 1, 8))
    end

    it "siempre devuelve un viernes posterior a hoy" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 31)).each do |day|
        result = calendar_on(day).maximum_publish_date

        expect(result).to be_friday
        expect(result).to be > day
      end
    end
  end

  describe ".last_saturday" do
    {
      "un mes que termina en sábado" => [ Date.new(2026, 10, 1), Date.new(2026, 10, 31) ],
      "un mes que termina en domingo" => [ Date.new(2027, 1, 1), Date.new(2027, 1, 30) ],
      "un mes que termina en lunes" => [ Date.new(2026, 11, 1), Date.new(2026, 11, 28) ],
      "un mes que termina en jueves" => [ Date.new(2026, 12, 1), Date.new(2026, 12, 26) ],
      "un mes que termina en viernes" => [ Date.new(2027, 4, 1), Date.new(2027, 4, 24) ],
      "febrero no bisiesto" => [ Date.new(2027, 2, 1), Date.new(2027, 2, 27) ],
      "febrero bisiesto" => [ Date.new(2028, 2, 1), Date.new(2028, 2, 26) ]
    }.each do |description, (month_start, expected)|
      it "devuelve #{expected} para #{description}" do
        expect(described_class.last_saturday(month_start)).to eq(expected)
      end
    end

    it "siempre devuelve un sábado dentro del mismo mes, en los últimos 7 días" do
      (Date.new(2026, 1, 1)..Date.new(2030, 12, 1)).select { |d| d.day == 1 }.each do |month_start|
        result = described_class.last_saturday(month_start)

        expect(result).to be_saturday
        expect(result.beginning_of_month).to eq(month_start)
        expect(result).to be > month_start.end_of_month - 7.days
      end
    end
  end
end
