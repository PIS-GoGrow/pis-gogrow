# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeeDebtNotifications do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts, :payments

  let(:company) { companies(:gogrow) }
  let(:provider) { providers(:endulzate) }
  let(:admin_user) { users(:admin) }
  let(:other_admin_user) do
    Admin.create!(user: users(:two), company:)
    users(:two)
  end
  # El plazo de abril vence el 10 de mayo y el del mes siguiente, el 10 de junio:
  # la deuda de abril se avisa desde el 11 de junio. Las fixtures usan meses
  # cercanos a hoy, así que con estas fechas no entran en las pruebas.
  let(:april) { Date.new(2026, 4, 1) }
  let!(:company_account) { Account.create!(owner: company, provider:, month: april, amount: 300) }
  let!(:one_account) { Account.create!(owner: consumers(:one), provider:, month: april, amount: 200) }
  let(:other_account) { Account.create!(owner: consumers(:other), provider:, month: april, amount: 100) }

  def remind_on(date)
    travel_to(date) { described_class.remind! }
  end

  def alerts(user)
    user.notifications.where(event: "employee_debt_overdue")
  end

  def add_payment(status:, to:, **attributes)
    payment = to.payments.build(provider: to.provider, status:, **attributes)
    payment.receipt.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "comprobante.png")
    payment.save!
    payment
  end

  describe ".remind!" do
    it "no avisa mientras no venció el plazo de pago del mes siguiente" do
      expect { remind_on(Date.new(2026, 6, 10)) }.not_to change(Notification, :count)
    end

    it "avisa desde que venció ese plazo, nombrando al empleado cuando es uno solo" do
      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole).to have_attributes(
        notifiable: company_account,
        role: "admin",
        requires_action: false,
        title: "Hay empleados con pagos pendientes",
        description: "Test User tiene pendiente su pago a Other Provider User correspondiente a abril 2026. " \
                     "La deuda asciende a $200. Podés enviarle un recordatorio."
      )
    end

    it "avisa la cantidad de empleados y la deuda total cuando son varios" do
      other_account

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to eq(
        "2 empleados tienen pendiente su pago a Other Provider User correspondiente a abril 2026. " \
        "La deuda total asciende a $300. Podés enviarles un recordatorio."
      )
    end

    it "avisa a todos los admins de la empresa y no a los de otra" do
      other_admin_user
      other_company = Company.create!(name: "Otra empresa", address: "Ellauri 1234")
      outsider = User.create!(email: "admin-otra-empresa@gmail.com", name: "Admin Externo", password: "password123456")
      Admin.create!(user: outsider, company: other_company)
      outsider_consumer = Consumer.create!(
        user: User.create!(email: "consumer-otra-empresa@gmail.com", name: "Empleado Externo", password: "password123456"),
        company: other_company,
        address: "Ellauri 1234"
      )
      outsider_company_account = Account.create!(owner: other_company, provider:, month: april, amount: 50)
      Account.create!(owner: outsider_consumer, provider:, month: april, amount: 50)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.map(&:notifiable)).to eq([ company_account ])
      expect(alerts(other_admin_user).active.map(&:notifiable)).to eq([ company_account ])
      expect(alerts(outsider).active.map(&:notifiable)).to eq([ outsider_company_account ])
    end

    it "crea un aviso por cada proveedor y mes, no uno por empleado" do
      other_account
      march_company_account = Account.create!(owner: company, provider:, month: Date.new(2026, 3, 1), amount: 50)
      Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 3, 1), amount: 50)
      office = providers(:office_provider)
      office_company_account = Account.create!(owner: company, provider: office, month: april, amount: 80)
      Account.create!(owner: consumers(:other), provider: office, month: april, amount: 80)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.map(&:notifiable))
        .to match_array([ company_account, march_company_account, office_company_account ])
    end

    it "no avisa por los meses cuyo plazo siguiente todavía no venció" do
      Account.create!(owner: company, provider:, month: Date.new(2026, 5, 1), amount: 50)
      Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.map(&:notifiable)).to eq([ company_account ])
    end

    it "no avisa por empleados que ya pagaron o cuyo comprobante está en revisión" do
      add_payment(status: :approved, to: one_account)
      add_payment(status: :submitted, to: other_account)

      expect { remind_on(Date.new(2026, 6, 11)) }.not_to change(Notification, :count)
    end

    it "sigue avisando cuando el último comprobante fue rechazado" do
      add_payment(status: :rejected, rejection_reason: "Comprobante ilegible", to: one_account)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.count).to eq(1)
    end

    it "no avisa si la empresa no tiene cuenta con ese proveedor en ese mes" do
      company_account.destroy!

      expect { remind_on(Date.new(2026, 6, 11)) }.not_to change(Notification, :count)
    end

    it "no duplica el aviso si el job corre más de una vez" do
      remind_on(Date.new(2026, 6, 11))

      expect { remind_on(Date.new(2026, 6, 11)) }.not_to change(Notification, :count)
    end

    it "no crea un segundo aviso mientras el anterior sigue abierto" do
      remind_on(Date.new(2026, 6, 11))

      expect { remind_on(Date.new(2026, 7, 11)) }.not_to change(Notification, :count)
    end

    it "actualiza el aviso activo cuando cambia la cantidad de deudores" do
      other_account
      remind_on(Date.new(2026, 6, 11))
      notification = alerts(admin_user).active.sole

      other_account.update!(amount: 0)
      remind_on(Date.new(2026, 6, 12))

      expect(alerts(admin_user).active.sole).to eq(notification)
      expect(notification.reload.description).to eq(
        "Test User tiene pendiente su pago a Other Provider User correspondiente a abril 2026. " \
        "La deuda asciende a $200. Podés enviarle un recordatorio."
      )
    end

    it "cierra el aviso cuando ya no quedan deudores" do
      remind_on(Date.new(2026, 6, 11))

      one_account.update!(amount: 0)
      remind_on(Date.new(2026, 6, 12))

      expect(alerts(admin_user).active).to be_empty
      expect(alerts(admin_user).closed.count).to eq(1)
    end

    it "no vuelve a crear un aviso que RR.HH. cerró hasta que pasa un mes" do
      remind_on(Date.new(2026, 6, 11))
      alerts(admin_user).active.sole.close!

      remind_on(Date.new(2026, 6, 12))
      remind_on(Date.new(2026, 7, 10))

      expect(alerts(admin_user).active).to be_empty

      remind_on(Date.new(2026, 7, 11))

      expect(alerts(admin_user).active.count).to eq(1)
    end
  end

  describe "al cambiar el estado de un pago de un empleado" do
    before do
      other_account
      remind_on(Date.new(2026, 6, 11))
    end

    it "actualiza el aviso cuando uno de los deudores informa su comprobante" do
      add_payment(status: :submitted, to: other_account)

      expect(alerts(admin_user).active.sole.description).to eq(
        "Test User tiene pendiente su pago a Other Provider User correspondiente a abril 2026. " \
        "La deuda asciende a $200. Podés enviarle un recordatorio."
      )
    end

    it "cierra el aviso cuando ya no queda ningún deudor" do
      add_payment(status: :submitted, to: other_account)
      add_payment(status: :submitted, to: one_account)

      expect(alerts(admin_user).active).to be_empty
      expect(alerts(admin_user).closed.count).to eq(1)
    end

    it "actualiza el mismo aviso cuando el proveedor rechaza un comprobante" do
      notification = alerts(admin_user).active.sole
      add_payment(status: :submitted, to: other_account).reject_with("Comprobante ilegible")

      expect(alerts(admin_user).active.sole).to eq(notification)
      expect(notification.reload.description).to start_with("2 empleados tienen pendiente")
    end

    it "vuelve a avisar cuando un rechazo devuelve la deuda de un empleado que ya la había resuelto" do
      add_payment(status: :submitted, to: one_account)
      add_payment(status: :submitted, to: other_account).reject_with("Comprobante ilegible")

      expect(alerts(admin_user).active.sole.description).to eq(
        "Other Consumer User tiene pendiente su pago a Other Provider User correspondiente a abril 2026. " \
        "La deuda asciende a $100. Podés enviarle un recordatorio."
      )
    end

    it "no avisa por un rechazo de un mes cuyo plazo siguiente todavía no venció" do
      may_company_account = Account.create!(owner: company, provider:, month: Date.new(2026, 5, 1), amount: 50)
      may_account = Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50)

      travel_to(Date.new(2026, 6, 11)) do
        add_payment(status: :submitted, to: may_account).reject_with("Comprobante ilegible")
      end

      expect(alerts(admin_user).active.map(&:notifiable)).to eq([ company_account ])
      expect(alerts(admin_user).active.map(&:notifiable)).not_to include(may_company_account)
    end
  end

  describe ".refresh" do
    it "ignora las cuentas de la empresa" do
      expect(described_class.refresh(company_account)).to be_nil
    end
  end
end
