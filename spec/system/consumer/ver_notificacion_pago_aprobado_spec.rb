# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ver notificación de pago aprobado para empleado", type: :system do
  fixtures :users, :companies, :providers, :consumers, :accounts, :payments

  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:account) { accounts(:one_tuviandita_current) }
  let(:title) { "Pago aprobado" }

  before do
    Notification::Configuration.find_or_create_by!(key: "automatic_payment_reminders") do |c|
      c.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)
  end

  def setup_submitted_payment
    payment = account.payments.build(provider: providers(:tuviandita), status: :submitted)
    payment.receipt.attach(
      io: StringIO.new("test-receipt"),
      filename: "receipt.png",
      content_type: "image/png"
    )
    payment.save!
    payment
  end

  def approve_payment_as_provider(payment)
    payment.approve
  end

  it "le muestra al empleado el banner de pago aprobado con el proveedor y período, y permite cerrarlo" do
    payment = setup_submitted_payment

    sign_in consumer_user, role: :consumer
    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
    sign_out

    approve_payment_as_provider(payment)

    sign_in consumer_user, role: :consumer
    visit dashboard_path
    open_notifications

    expect(page).to have_content(title)
    expected_period = I18n.l(account.month, format: "%B %Y")
    expect(page).to have_content(
      "#{provider_user.name} aprobó tu comprobante de pago correspondiente a #{expected_period}."
    )

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)
  end
end
