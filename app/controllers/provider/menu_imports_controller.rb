# frozen_string_literal: true

# Importar un menú desde una planilla, en dos pasos: la vista previa, que no
# toca la base, y la confirmación. El archivo no queda guardado en el servidor
# entre los dos: el navegador lo manda de nuevo al confirmar.
# Ver docs/importar-menu.md.
class Provider::MenuImportsController < Provider::InertiaController
  PAGE = "provider/menu_imports/new"
  TEMPLATE_PATH = "/plantillas/menu.csv"

  before_action :set_instructions

  def new; end

  def create
    render_preview(plan)
  end

  def confirm
    import = plan
    save = Menus::Import::Save.new(provider:, plan: import, by: Current.user)
    return render_preview(import, save.errors) unless save.call

    redirect_to schedules_path(tab: "saved"), notice: t("flash.menu_imported", count: import.entries.size)
  end

  private

  def provider = Current.user.provider

  # El plan se arma de nuevo en cada paso, con el archivo que llega en el
  # pedido: así nada queda a medias si el proveedor abandona la vista previa.
  def plan
    Menus::Import::Plan.new(
      provider:,
      path: uploaded_file&.tempfile&.path.to_s,
      filename: uploaded_file&.original_filename
    ).tap(&:call)
  end

  def uploaded_file = params[:file].respond_to?(:tempfile) ? params[:file] : nil

  # Los errores de `save` son los que recién se ven al guardar: se muestran en
  # la misma fila que los de la vista previa.
  def render_preview(plan, errors = {})
    @preview = {
      error: plan.error,
      filename: uploaded_file&.original_filename,
      can_import: plan.valid? && errors.empty?,
      entries: plan.entries.map do |entry|
        { number: entry.number, name: entry.name, action: entry.action, errors: entry.errors + errors.fetch(entry.number, []) }
      end
    }

    render_inertia PAGE, serializer: Provider::MenuImportsNewSerializer
  end

  def set_instructions
    @template_path = TEMPLATE_PATH
    @max_rows = Menus::Import::Sheet::MAX_ROWS
    @max_size_mb = Menus::Import::Plan::MAX_SIZE / 1.megabyte
    @preview = nil
  end
end
