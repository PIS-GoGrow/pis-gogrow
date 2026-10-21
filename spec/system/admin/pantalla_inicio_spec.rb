# frozen_string_literal: true

# Historia IBP-076: "Como RRHH, quiero visualizar una pantalla de inicio, para
# comprender qué puedo hacer con la aplicación según mi perfil." No tiene
# criterios de aceptación: se prueba el enunciado.

require "rails_helper"

RSpec.describe "Pantalla de inicio de RRHH", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers

  let(:admin_user) { users(:admin) }

  def sidebar
    find("[data-sidebar='sidebar']")
  end

  # El login con Google redirige a la raíz: de ahí tiene que llegar al inicio
  # de RR. HH. y no a la bienvenida del starter kit.
  it "lands HR on its home from the root page" do
    sign_in admin_user, role: :admin
    visit root_path

    expect(page).to have_current_path(admin_dashboard_path)
    expect(page).to have_content("Hola, #{admin_user.name.split.first}")
  end

  it "greets HR and shows the summary of the month" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    expect(page).to have_content("Hola, #{admin_user.name.split.first}")
    expect(page).to have_content(I18n.l(Date.current, format: "%A %-d de %B").capitalize)
    expect(page).to have_content("Tu beneficio")
    expect(page).to have_content("Tus pagos de #{I18n.l(Date.current.prev_month, format: "%B").downcase}")
    expect(page).to have_content("Ranking deuda de empleados")
  end

  # Historia IBP-032: el chevron del ranking abre Empleados en Pendientes y
  # cada empleado, su detalle.
  it "goes from the debt ranking to the pending employees and to an employee" do
    company = companies(:gogrow)
    consumer = Consumer.create!(user: User.create!(name: "Martín Bonnet", email: "martin@example.com", password: "secret-password-123"), company:)
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: Date.current, amount: 2_425)

    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    click_on "Ver empleados con saldos pendientes"
    expect(page).to have_current_path(admin_consumers_path(filter: "pending"))
    expect(page).to have_css("[role='radio'][aria-checked='true']", text: "Pendientes")

    visit admin_dashboard_path
    click_on "Martín Bonnet"
    expect(page).to have_current_path(admin_consumer_path(consumer))
  end

  it "keeps the month chosen on the home when it opens the pending employees" do
    previous = 1.month.ago.to_date.beginning_of_month
    consumer = Consumer.create!(user: User.create!(name: "Martín Bonnet", email: "martin@example.com", password: "secret-password-123"), company: companies(:gogrow))
    Account.create!(owner: consumer, provider: providers(:tuviandita), month: previous, amount: 2_425)

    sign_in admin_user, role: :admin
    visit admin_dashboard_path(month: previous.strftime("%Y-%m"))

    click_on "Ver empleados con saldos pendientes"
    expect(page).to have_current_path(admin_consumers_path(filter: "pending", month: previous.strftime("%Y-%m")))
    expect(page).to have_content("Martín Bonnet")
  end

  it "shows in the navigation what HR can use now and what is still to come" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    within(sidebar) do
      expect(page).to have_css("[data-active='true']", text: "Inicio")
      expect(page).to have_link("Subsidios")
      expect(page).to have_link("Empleados")
      expect(page).to have_link("Cuenta")
      expect(page).to have_link("Pagos", href: admin_payments_path)
    end
  end

  it "goes from the home to an available section and back" do
    sign_in admin_user, role: :admin
    visit admin_dashboard_path

    within(sidebar) { click_on "Subsidios" }
    expect(page).to have_current_path(admin_benefit_configurations_path)

    within(sidebar) { click_on "Inicio" }
    expect(page).to have_current_path(admin_dashboard_path)
    expect(page).to have_content("Hola,")
  end

  describe "permissions" do
    it "sends a visitor to sign in" do
      visit admin_dashboard_path

      expect(page).to have_current_path(sign_in_path)
    end

    it "keeps a consumer and a provider out of the HR home" do
      sign_in users(:one), role: :consumer
      visit admin_dashboard_path
      expect(page).to have_no_current_path(admin_dashboard_path)

      sign_out
      sign_in users(:provider_user), role: :provider
      visit admin_dashboard_path
      expect(page).to have_no_current_path(admin_dashboard_path)
    end
  end
end
