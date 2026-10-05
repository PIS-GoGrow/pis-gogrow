# frozen_string_literal: true

require "rails_helper"

# Historia: "Como EMPLEADO, quiero consultar la información de mi cuenta,
# incluyendo nombre, email corporativo, foto de perfil y beneficio asignado,
# para disponer de mi información personal y poder cerrar sesión."
#
# La pantalla es /profile, a donde el sidebar del empleado manda con "Cuenta".
# El nombre, el email y la foto viajan en las props compartidas (auth.user), así
# que lo que esta pantalla agrega por su cuenta es el beneficio.
#
# Criterio 1 incompleto: el criterio pide ver la "foto de perfil", pero ningún
# fixture de users.yml define avatar_url, así que UserSerializer#avatar devuelve
# nil y el <AvatarImage> nunca monta la imagen: lo que el empleado ve es el
# AvatarFallback con sus iniciales. Estos ejemplos comprueban el avatar
# identificado por nombre y el respaldo con iniciales, que es lo que se puede
# observar hoy; el camino de la imagen real queda sin ejercitar. Ver
# docs/reports/defects/DEFECT-avatar-sin-fixture-05-10-2026.md
RSpec.describe "Consultar la información de la cuenta del empleado" do
  fixtures :users, :companies, :consumers, :providers,
          :benefit_configurations, :benefit_rules, :benefits

  let(:employee) { users(:one) }
  let(:benefit) { benefits(:monthly) }
  let(:consumer) { consumers(:one) }

  # El beneficio mensual de benefits.yml vence dos días después de hoy, así que la
  # fecha que muestra la pantalla se arma acá y no hardcodeada: si el fixture se
  # mueve, el ejemplo sigue siendo cierto.
  let(:due_date_label) { I18n.l(benefit.due_date, format: "%d/%m/%Y") }
  let(:initials) { employee.name.split.map { |part| part[0] }.join.upcase }

  # Criterio 1 -- nombre, email y foto. El Avatar cae a iniciales porque el
  # fixture no tiene avatar_url: se afirma el respaldo, no una imagen.
  it "shows the employee's name, corporate email and profile photo" do
    sign_in employee

    visit profile_path

    expect(page).to have_content(employee.name)
    expect(page).to have_content(employee.email)
    expect(page).to have_css("[data-slot=avatar-fallback]", text: initials)
  end

  # Criterio 1 -- beneficio asignado. Los números salen del benefit del fixture
  # y de lo que el empleado ya consumió, no de valores fijos.
  it "shows the benefit assigned to the employee" do
    sign_in employee

    visit profile_path

    within(find("section[aria-labelledby=benefit-title]")) do
      expect(page).to have_content("#{benefit.percentage} %")
      expect(page).to have_content("#{consumer.monthly_benefit_available} viandas")
      expect(page).to have_content(due_date_label)
    end
  end

  # Criterio 1 -- lo que queda del beneficio depende de lo que este empleado ya
  # consumió: se afirma contra su propio Consumer, no contra un número fijo.
  it "reports how many of the employee's subsidized meals are left this month" do
    sign_in employee

    visit profile_path

    within(find("section[aria-labelledby=benefit-title]")) do
      expect(page).to have_content("#{consumer.remaining_monthly_benefit} viandas")
    end
  end

  # Criterio 1 -- el caso de partida: sin beneficio se explica, en vez de
  # mostrar ceros que parecerían un beneficio agotado.
  it "explains that there is no benefit assigned instead of showing zeroes" do
    benefit.destroy!
    sign_in employee

    visit profile_path

    within(find("section[aria-labelledby=benefit-title]")) do
      expect(page).to have_content(/Todavía no tenés un beneficio/)
      expect(page).to have_no_content("0 viandas")
    end
  end

  # Criterio 2 -- cerrar sesión. No alcanza con que el botón exista: tiene que
  # destruir la sesión de verdad y dejar la pantalla sin acceso. SessionsController
  # redirige a root_path y es HomeController el que rebota a sign_in, así que no se
  # afirma la URL del redirect sino el efecto: la sesión ya no existe y /profile
  # manda a sign in.
  #
  # FALLA HOY, y por un defecto de la app, no del spec: show.tsx:50 pasa el objeto
  # entero de sessions.destroy(...) al href del <Link> en vez de su .url, así que el
  # DELETE nunca se dispara y la sesión sigue viva. El criterio 2 de la historia está
  # sin cumplir. Ver
  # docs/reports/defects/DEFECT-salir-no-cierra-sesion-05-10-2026.md
  it "signs the employee out from the account screen" do
    sign_in employee
    visit profile_path
    session_id = employee.sessions.order(:id).last

    click_on "Salir"

    # Session.exists? y no reload: recargar una fila ya borrada devuelve un objeto
    # nuevo que no sabe del delete, así que destroyed? seguiría en false.
    expect(Session.exists?(session_id.id)).to be false

    visit profile_path
    expect(page).to have_current_path(sign_in_path)
  end

  # Transversal -- permisos: la pantalla es del empleado y no se alcanza con otro
  # rol ni sin sesión, y el rebote no filtra ningún dato en el HTML.
  it "does not let a provider reach the account screen" do
    sign_in users(:provider_user), role: :provider

    visit profile_path

    expect(page).to have_no_current_path(profile_path)
    expect(page).to have_no_content(employee.name)
    expect(page).to have_no_content(employee.email)
  end

  it "sends a visitor without a session to sign in" do
    visit profile_path

    expect(page).to have_current_path(sign_in_path)
    expect(page).to have_no_content(employee.name)
  end

  # Transversal -- privacidad entre empleados del mismo rol. La pantalla siempre
  # lee Current.user, así que el beneficio del otro no aparece ni por URL directa:
  # no hay id de beneficio en la ruta que se pueda cambiar.
  it "keeps another employee's benefit out of the account screen" do
    sign_in employee

    visit profile_path

    expect(page).to have_no_content(benefits(:one).description)
    expect(page).to have_no_content(benefits(:two).description)
    expect(page).to have_content("#{benefit.amount} viandas")
  end

  # Transversal -- persistencia: la información sigue ahí después de un reload y
  # de un ida y vuelta de sesión.
  it "keeps the account information across a reload and signing out and in again" do
    sign_in employee

    visit profile_path
    expect(page).to have_content(employee.name)
    expect(page).to have_content(due_date_label)

    refresh
    expect(page).to have_content(employee.name)
    expect(page).to have_content(due_date_label)

    sign_out
    sign_in employee
    visit profile_path

    expect(page).to have_content(employee.name)
    expect(page).to have_content(employee.email)
    expect(page).to have_content(due_date_label)
  end
end
