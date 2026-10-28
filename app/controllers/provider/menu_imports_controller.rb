# frozen_string_literal: true

# Importar un menú desde una planilla, en dos pasos. El primero lee el archivo y
# devuelve la vista previa, que no toca la base. El segundo recibe la lista ya
# revisada por el proveedor —con lo que quitó, editó y decidió actualizar— y la
# guarda. La planilla no queda en el servidor entre uno y otro.
# Ver docs/importar-menu.md.
class Provider::MenuImportsController < Provider::InertiaController
  PAGE = "provider/menu_imports/new"
  TEMPLATE_PATH = "/plantillas/menu.csv"

  before_action :set_instructions

  def new
    render_page
  end

  def create
    plan = Menus::Import::Plan.new(path: uploaded_file&.tempfile&.path.to_s, filename: uploaded_file&.original_filename)
    plan.call

    @preview = Menus::Import::Preview.call(plan:, filename: uploaded_file&.original_filename)
    render_page
  end

  def confirm
    entries = reviewed_entries
    return head :unprocessable_content if entries.size > Menus::Import::Sheet::MAX_ROWS

    save = Menus::Import::Save.new(provider:, entries:, by: Current.user)

    if save.call
      @imported = { count: save.count }
    else
      @row_errors = save.errors
    end

    # La planilla que se estaba revisando sigue en el navegador: se le devuelve
    # su identidad para que la pantalla no se desarme detrás del aviso. Las
    # filas no viajan de vuelta porque allá están, ya revisadas.
    @preview = { id: params[:preview_id].to_s, filename: params[:filename], error: nil, entries: [] }

    render_page
  end

  private

  def provider = Current.user.provider

  def uploaded_file = params[:file].respond_to?(:tempfile) ? params[:file] : nil

  # Lo que el proveedor revisó en la pantalla. Llega del navegador, así que el
  # id del plato a actualizar se vuelve a buscar entre los suyos al guardar.
  def reviewed_entries
    params
      .permit(entries: [
        :key, :action, :menu_id, :name, :description, :price, :confirmed_orders,
        { agenda: [ :mode, :date, :starts_on, :ends_on, :amount, { weekdays: [] } ] },
        { option_groups: [ :name, :limit, :required, { options: [] } ] }
      ])
      .fetch(:entries, [])
      .map { it.to_h.deep_symbolize_keys }
  end

  def render_page = render_inertia(PAGE, serializer: Provider::MenuImportsNewSerializer)

  def set_instructions
    @template_path = TEMPLATE_PATH
    @formats = Menus::Import::Sheet::EXTENSIONS.keys
    @max_rows = Menus::Import::Sheet::MAX_ROWS
    @max_size_mb = Menus::Import::Plan::MAX_SIZE / 1.megabyte
    @saved_menus = Menus::Import::SavedMenus.call(provider:)
    @today = Date.current.iso8601
    @maximum_publish_date = Calendar.new.maximum_publish_date.iso8601
    @preview = nil
    @imported = nil
    @row_errors = {}
  end
end
