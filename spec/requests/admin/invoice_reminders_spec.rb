# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::InvoiceReminders", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers, :accounts, :payments

  let(:account) { accounts(:gogrow_tuviandita_previous) }
  let(:provider_user) { users(:provider_user) }

  # Ningún test habla con Twilio: alcanza con saber que el envío se encoló.
  before { allow(WhatsappSenderJob).to receive(:perform_later) }

  def upload
    Rack::Test::UploadedFile.new(Rails.root.join("public/icon.png"), "image/png", original_filename: "factura.png")
  end

  def remind(target = account)
    post admin_payment_invoice_reminders_path(target), headers: { "HTTP_REFERER" => admin_payments_path }
  end

  def reminders
    Notification.where(event: "invoice_reminder", notifiable: account)
  end

  describe "POST /rrhh/pagos/:payment_id/recordatorios-de-factura" do
    it "redirige al inicio de sesión cuando no hay sesión activa" do
      remind

      expect(response).to redirect_to(admin_welcome_path)
    end

    it "redirige al inicio cuando el usuario es un empleado" do
      sign_in users(:one), role: :consumer

      expect { remind }.not_to change(Notification, :count)
      expect(response).to redirect_to(root_path)
    end

    it "redirige al inicio cuando el usuario es un proveedor" do
      sign_in provider_user, role: :provider

      expect { remind }.not_to change(Notification, :count)
      expect(response).to redirect_to(root_path)
    end

    it "devuelve 404 ante la cuenta de otra empresa" do
      other_company = Company.create!(name: "Otra empresa", address: "Rincón 500")
      other_account = Account.create!(owner: other_company, provider: providers(:tuviandita), month: 1.month.ago.beginning_of_month, amount: 100)
      sign_in users(:admin), role: :admin

      expect { remind(other_account) }.not_to change(Notification, :count)
      expect(response).to have_http_status(:not_found)
    end

    context "cuando lo manda RR. HH." do
      before { sign_in users(:admin), role: :admin }

      it "le avisa al proveedor del período que envíe la factura" do
        expect { remind }.to change(Notification, :count).by(1)

        notification = reminders.sole
        expect(notification).to have_attributes(user: provider_user, role: "provider", requires_action: true)
        expect(notification.description).to eq(
          "#{companies(:gogrow).name} te recuerda enviar la factura de " \
          "#{I18n.l(account.month, format: :month_name_year).downcase}. Podés cargarla desde Cobros."
        )
        expect(response).to redirect_to(admin_payments_path)
        expect(flash[:notice]).to eq("Le recordamos a #{provider_user.name} que envíe la factura.")
      end

      it "no lo manda si el proveedor ya envió la factura" do
        account.invoices.create!(issued_on: Date.current, total_amount: 900, file: upload)

        expect { remind }.not_to change(Notification, :count)
        expect(flash[:alert]).to eq("El proveedor ya envió la factura de este período.")
      end

      it "no lo manda para el mes en curso" do
        expect { remind(accounts(:gogrow_tuviandita_current)) }.not_to change(Notification, :count)
        expect(flash[:alert]).to eq("Podés recordar la factura cuando cierre el mes.")
      end

      it "espera tres días para volver a mandarlo" do
        remind

        travel 3.days - 1.minute do
          expect { remind }.not_to change(Notification, :count)
          expect(flash[:alert]).to eq("Todavía no podés enviar otro recordatorio.")
        end

        travel 3.days + 1.minute do
          expect { remind }.to change(Notification, :count).by(1)
          expect(reminders.active.count).to eq(1)
        end
      end

      it "muestra hasta cuándo hay que esperar en Pagos" do
        account.payments.destroy_all
        remind

        get admin_payments_path

        expect(inertia.props[:accounts].find { it[:id] == account.id }[:invoice_reminder_days_left]).to eq(3)

        travel 2.days + 1.hour do
          get admin_payments_path

          expect(inertia.props[:accounts].find { it[:id] == account.id }[:invoice_reminder_days_left]).to eq(1)
        end
      end
    end
  end

  describe "al subir la factura" do
    it "cierra el recordatorio del proveedor" do
      sign_in users(:admin), role: :admin
      remind

      account.invoices.create!(issued_on: Date.current, total_amount: 900, file: upload)

      expect(reminders.sole.closed_at).to be_present
    end
  end
end
