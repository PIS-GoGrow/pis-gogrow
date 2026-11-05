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
  # la deuda de abril se avisa desde el 11 de junio. El importe es la deuda total
  # de cada empleado, así que las cuentas de las fixtures quedan en cero.
  let(:april) { Date.new(2026, 4, 1) }

  before { Account.where(owner_type: "Consumer").update_all(amount: 0) }

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

    it "avisa desde que venció ese plazo" do
      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole).to have_attributes(
        notifiable: company,
        role: "admin",
        requires_action: false,
        title: "Hay empleados con pagos pendientes",
        description: "1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio."
      )
    end

    it "avisa la cantidad de empleados y la deuda total cuando son varios" do
      other_account

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to eq(
        "2 empleados tienen una deuda total de $300. Podés enviarles un recordatorio."
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
      Account.create!(owner: outsider_consumer, provider:, month: april, amount: 50)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.map(&:notifiable)).to eq([ company ])
      expect(alerts(other_admin_user).active.map(&:notifiable)).to eq([ company ])
      expect(alerts(outsider).active.map(&:notifiable)).to eq([ other_company ])
    end

    it "crea un solo aviso con los empleados y su deuda total aunque deban a varios proveedores y meses" do
      other_account
      Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 3, 1), amount: 50)
      Account.create!(owner: consumers(:other), provider: providers(:office_provider), month: april, amount: 80)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to eq(
        "2 empleados tienen una deuda total de $430. Podés enviarles un recordatorio."
      )
    end

    it "no cuenta a quien solo debe meses cuyo plazo siguiente todavía no venció" do
      Account.create!(owner: consumers(:other), provider:, month: Date.new(2026, 5, 1), amount: 50)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to eq("1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio.")
    end

    it "suma todo lo que debe el empleado, también lo que todavía no venció" do
      Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to start_with("1 empleado tiene una deuda total de $250.")
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

    it "sigue considerando deuda un pago parcial" do
      add_payment(status: :partial, to: one_account)

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.sole.description).to eq("1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio.")
    end

    it "avisa aunque la empresa no tenga cuenta con ese proveedor en ese mes" do
      company_account.destroy!

      remind_on(Date.new(2026, 6, 11))

      expect(alerts(admin_user).active.count).to eq(1)
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
      expect(notification.reload.description).to eq("1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio.")
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

    it "vuelve a crear un aviso cerrado cuando aparece un período vencido más nuevo, sin esperar el mes" do
      Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50)
      remind_on(Date.new(2026, 6, 20))
      alerts(admin_user).active.sole.close!

      remind_on(Date.new(2026, 7, 10))

      expect(alerts(admin_user).active).to be_empty

      remind_on(Date.new(2026, 7, 11))

      expect(alerts(admin_user).active.count).to eq(1)
    end
  end

  describe "avisos anteriores, colgados de la cuenta de la empresa" do
    let!(:legacy) do
      Notifier.call(event_key: :employee_debt_overdue, user: admin_user, notifiable: company_account, description_data: { count: 2, amount: "$1" })
    end

    it "los cierra y deja el aviso de la empresa" do
      remind_on(Date.new(2026, 6, 11))

      expect(legacy.reload.closed_at).to be_present
      expect(alerts(admin_user).active.sole.notifiable).to eq(company)
    end

    it "los cierra aunque ya nadie deba" do
      one_account.update!(amount: 0)

      remind_on(Date.new(2026, 6, 11))

      expect(legacy.reload.closed_at).to be_present
      expect(alerts(admin_user).active).to be_empty
    end
  end

  describe "al cambiar el importe de una cuenta de un empleado" do
    let!(:may_account) { Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50) }

    before do
      other_account
      remind_on(Date.new(2026, 6, 11))
    end

    it "actualiza el importe, aunque la cuenta no sea de deuda vencida" do
      may_account.sync_amount!

      expect(alerts(admin_user).active.sole.description).to eq(
        "2 empleados tienen una deuda total de $300. Podés enviarles un recordatorio."
      )
    end

    it "deja de contar a quien ya no tiene deuda vencida" do
      other_account.sync_amount!

      expect(alerts(admin_user).active.sole.description).to start_with("1 empleado tiene una deuda total de $250.")
    end

    it "cierra el aviso si ya nadie tiene deuda vencida" do
      [ other_account, one_account, may_account ].each(&:sync_amount!)

      expect(alerts(admin_user).active).to be_empty
    end

    it "no crea un aviso nuevo si RR.HH. cerró el anterior" do
      alerts(admin_user).active.sole.close!

      expect { may_account.sync_amount! }.not_to change(Notification, :count)
    end
  end

  describe "al cambiar el estado de un pago de un empleado" do
    before do
      other_account
      remind_on(Date.new(2026, 6, 11))
    end

    it "actualiza el aviso cuando uno de los deudores informa su comprobante" do
      add_payment(status: :submitted, to: other_account)

      expect(alerts(admin_user).active.sole.description).to eq("1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio.")
    end

    it "baja el importe cuando un comprobante aprobado cubre parte de la deuda" do
      add_payment(status: :approved, to: other_account, expected_amount: 60)

      expect(alerts(admin_user).active.sole.description).to eq(
        "2 empleados tienen una deuda total de $240. Podés enviarles un recordatorio."
      )
    end

    # Defecto B5: el pago parcial no registra cuánto se pagó.
    it "todavía no baja el importe con el pago parcial del proveedor" do
      add_payment(status: :submitted, to: other_account).mark_partial

      expect(alerts(admin_user).active.sole.description).to start_with("2 empleados tienen una deuda total de $300.")
    end

    it "actualiza el aviso cuando un empleado paga todo" do
      add_payment(status: :approved, to: other_account)

      expect(alerts(admin_user).active.sole.description).to eq("1 empleado tiene una deuda total de $200. Podés enviarle un recordatorio.")
    end

    it "cierra el aviso cuando todos pagan" do
      add_payment(status: :approved, to: other_account)
      add_payment(status: :approved, to: one_account)

      expect(alerts(admin_user).active).to be_empty
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
      expect(notification.reload.description).to start_with("2 empleados tienen una deuda total")
    end

    it "actualiza el mismo aviso cuando un pago queda parcial sin tratarlo como rechazo" do
      notification = alerts(admin_user).active.sole
      payment = add_payment(status: :submitted, to: other_account)

      payment.mark_partial

      expect(alerts(admin_user).active.sole).to eq(notification)
      expect(notification.reload.description).to start_with("2 empleados tienen una deuda total")
    end

    it "vuelve a avisar cuando un rechazo devuelve la deuda de un empleado que ya la había resuelto" do
      add_payment(status: :submitted, to: one_account)
      add_payment(status: :submitted, to: other_account).reject_with("Comprobante ilegible")

      expect(alerts(admin_user).active.sole.description).to eq(
        "1 empleado tiene una deuda total de $100. Podés enviarle un recordatorio."
      )
    end

    it "no avisa por un rechazo de un mes cuyo plazo siguiente todavía no venció" do
      may_account = Account.create!(owner: consumers(:one), provider:, month: Date.new(2026, 5, 1), amount: 50)
      alerts(admin_user).active.sole.close!

      travel_to(Date.new(2026, 6, 11)) do
        add_payment(status: :submitted, to: may_account).reject_with("Comprobante ilegible")
      end

      expect(alerts(admin_user).active).to be_empty
    end
  end

  describe ".refresh" do
    it "ignora las cuentas de la empresa" do
      expect(described_class.refresh(company_account)).to be_nil
    end
  end
end
