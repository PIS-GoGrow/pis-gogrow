# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyPaymentNotifications do
  fixtures :users, :companies, :admins, :providers, :consumers, :accounts, :payments

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:other_admin_user) do
    Admin.create!(user: users(:two), company:)
    users(:two)
  end
  # Vence el 5 de septiembre: el aviso de que se aproxima sale desde el 2.
  let(:account) do
    Account.create!(owner: company, provider: providers(:endulzate), month: Date.new(2026, 8, 1), amount: 4500)
  end

  def active_events(user, notifiable = account)
    user.notifications.active.where(notifiable:).pluck(:event)
  end

  def add_payment(status:, to: account, **attributes)
    payment = to.payments.build(provider: to.provider, status:, **attributes)
    payment.receipt.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "comprobante.png")
    payment.save!
    payment
  end

  describe ".remind!" do
    it "no avisa antes de los 3 días previos al vencimiento" do
      account

      travel_to Date.new(2026, 9, 1) do
        expect { described_class.remind! }.not_to change(Notification, :count)
      end
    end

    it "avisa a todos los admins de la empresa que se aproxima el vencimiento, con proveedor, período e importe" do
      account
      other_admin_user

      travel_to Date.new(2026, 9, 2) do
        described_class.remind!
      end

      [ admin_user, other_admin_user ].each do |user|
        notification = user.notifications.active.find_by!(notifiable: account)
        expect(notification).to have_attributes(
          event: "company_payment_upcoming",
          role: "admin",
          requires_action: true,
          title: "Se acerca el vencimiento de un pago",
          description: "El pago de GoGrow a Other Provider User por agosto 2026 ($4.500) vence el 5/9/2026. Revisá el detalle en Pagos."
        )
      end
    end

    it "no duplica el aviso si el job corre más de una vez" do
      account

      travel_to Date.new(2026, 9, 2) do
        described_class.remind!
        expect { described_class.remind! }.not_to change(Notification, :count)
      end
    end

    it "reemplaza el aviso de que se aproxima por el de vencido al pasar la fecha" do
      account

      travel_to(Date.new(2026, 9, 3)) { described_class.remind! }
      travel_to Date.new(2026, 9, 6) do
        described_class.remind!
      end

      expect(active_events(admin_user)).to eq([ "company_payment_overdue" ])
      expect(admin_user.notifications.active.find_by!(notifiable: account).description)
        .to eq("El pago de GoGrow a Other Provider User por agosto 2026 ($4.500) venció el 5/9/2026. Revisá el detalle en Pagos.")
    end

    it "no avisa por cuentas con un comprobante enviado, aprobado o rechazado" do
      %i[submitted approved].each_with_index do |status, index|
        add_payment(status:, to: Account.create!(owner: company, provider: providers(:office_provider), month: Date.new(2026, 7 - index, 1), amount: 100))
      end
      add_payment(status: :rejected, rejection_reason: "Comprobante ilegible", to: account)

      travel_to Date.new(2026, 9, 6) do
        expect { described_class.remind! }.not_to change { admin_user.notifications.where(event: %w[company_payment_upcoming company_payment_overdue]).count }
      end
    end

    it "no avisa por cuentas sin deuda, del mes en curso ni de empleados" do
      Account.create!(owner: company, provider: providers(:endulzate), month: Date.new(2026, 8, 1), amount: 0)
      Account.create!(owner: company, provider: providers(:office_provider), month: Date.new(2026, 9, 1), amount: 300)
      Account.create!(owner: consumers(:one), provider: providers(:endulzate), month: Date.new(2026, 8, 1), amount: 200)

      travel_to Date.new(2026, 9, 6) do
        expect { described_class.remind! }.not_to change(Notification, :count)
      end
    end
  end

  describe "al cambiar el estado de un pago de la empresa" do
    before { travel_to Date.new(2026, 9, 6) }

    it "resuelve los avisos pendientes cuando RR.HH. sube el comprobante" do
      account
      described_class.remind!

      add_payment(status: :submitted)

      expect(active_events(admin_user)).to be_empty
      expect(admin_user.notifications.closed.where(notifiable: account).pluck(:event)).to eq([ "company_payment_overdue" ])
    end

    it "avisa cuando el proveedor rechaza el comprobante y lo resuelve con el siguiente" do
      payment = add_payment(status: :submitted)

      payment.reject_with("Comprobante ilegible")

      notification = admin_user.notifications.active.find_by!(notifiable: account)
      expect(notification).to have_attributes(
        event: "company_payment_rejected",
        requires_action: true,
        title: "Tu comprobante fue rechazado",
        description: "El comprobante que subiste fue rechazado por Other Provider User. Volvé a cargarlo para confirmar tu pago."
      )

      add_payment(status: :submitted)

      expect(active_events(admin_user)).to be_empty
    end

    it "avisa cuando el proveedor aprueba el pago, como notificación informativa" do
      add_payment(status: :submitted).approve

      notification = admin_user.notifications.active.find_by!(notifiable: account)
      expect(notification).to have_attributes(
        event: "company_payment_approved",
        requires_action: false,
        title: "Pago confirmado",
        description: "Other Provider User confirmó el pago de GoGrow por agosto 2026 ($4.500)."
      )
    end

    it "no avisa a RR.HH. por los pagos de los empleados" do
      consumer_account = Account.create!(owner: consumers(:one), provider: providers(:endulzate), month: Date.new(2026, 8, 1), amount: 200)

      expect { add_payment(status: :submitted, to: consumer_account).approve }
        .not_to change { admin_user.notifications.count }
    end
  end
end
