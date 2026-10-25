# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateFormat do
  describe ".long" do
    it "devuelve nil si la fecha es nil" do
      expect(described_class.long(nil)).to be_nil
    end

    it "formatea la fecha con el día de la semana en mayúscula y el mes en minúscula por defecto" do
      date = Date.new(2026, 10, 12)
      expect(described_class.long(date)).to eq("Lunes 12 de octubre")
    end

    it "formatea la fecha con el día de la semana en minúscula cuando inline es true" do
      date = Date.new(2026, 10, 12)
      expect(described_class.long(date, inline: true)).to eq("lunes 12 de octubre")
    end
  end

  describe ".short" do
    it "devuelve nil si la fecha es nil" do
      expect(described_class.short(nil)).to be_nil
    end

    it "formatea la fecha en formato corto dd/mm/aa" do
      date = Date.new(2026, 11, 5)
      expect(described_class.short(date)).to eq("05/11/26")
    end
  end

  describe ".long_with_time" do
    it "devuelve nil si el time es nil" do
      expect(described_class.long_with_time(nil)).to be_nil
    end

    it "formatea momento exacto con fecha larga y hora HH:MM" do
      time = Time.zone.local(2026, 11, 5, 14, 30)
      expect(described_class.long_with_time(time)).to eq("Jueves 5 de noviembre a las 14:30")
    end

    it "formatea momento exacto inline con día en minúscula" do
      time = Time.zone.local(2026, 11, 5, 14, 30)
      expect(described_class.long_with_time(time, inline: true)).to eq("jueves 5 de noviembre a las 14:30")
    end
  end

  describe ".short_range" do
    it "devuelve una sola fecha corta cuando from y to son iguales" do
      date = Date.new(2026, 10, 19)
      expect(described_class.short_range(date, date)).to eq("19/10/26")
    end

    it "devuelve el rango formateado con 'al' cuando from y to son distintos" do
      from = Date.new(2026, 10, 19)
      to = Date.new(2026, 10, 21)
      expect(described_class.short_range(from, to)).to eq("19/10/26 al 21/10/26")
    end
  end
end
