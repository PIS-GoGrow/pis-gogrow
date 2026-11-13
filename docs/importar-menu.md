# Importar un menú desde una planilla

El proveedor arma su menú en una planilla y la sube desde **Publicar menú** en
lugar de cargar los platos uno por uno. Este documento define el formato del
archivo, las decisiones que lo rodean y cómo se traduce a los modelos.

Ítem relacionado: IBP-052.

# Qué se decidió

**La planilla trae solo el plato: nombre, descripción, precio y opciones.** Los
días, el cupo y las fechas se ajustan después desde la aplicación. Pedirlos en
la planilla la volvía ancha y difícil de completar, y obligaba a explicar en una
celda algo que la pantalla de agenda ya resuelve mejor. Los platos importados
quedan en **Platos guardados**, sin programar.

**Formatos aceptados: `.xlsx`, `.xls`, `.csv` y `.ods`.** El `.xls` anterior a
2007 entra porque sigue siendo lo que exporta Excel por defecto en muchas
instalaciones; lo lee `roo-xls`, que roo 3 ya no trae.

**La lectura la hace la gema [roo](https://github.com/roo-rb/roo).** Lee los
cuatro formatos con la misma interfaz, está mantenida y es la más usada del
ecosistema por un margen amplio. Se descartaron `creek`, sin mantenimiento desde
2023, y `rubyXL`, de interfaz más incómoda. `caxlsx` resuelve el problema
contrario, escribir planillas, y haría falta solo si algún día la aplicación
genera una plantilla `.xlsx`.

**Un error en una fila no frena a las demás.** La vista previa marca la fila, el
proveedor la corrige ahí mismo o la quita, e importa el resto. La alternativa
—todo o nada— lo obligaba a volver a la planilla, corregir y subirla de nuevo
por un precio mal tipeado. Mientras quede una fila con error el botón de
importar está apagado: o se corrige o se quita, pero no se importa a medias.

**Un plato cuyo nombre ya existe no se importa salvo que el proveedor lo diga.**
La tarjeta ofrece tres caminos: **Editar** (cambiarle el nombre y que pase a ser
otro plato), **Duplicar** (crear uno nuevo con el mismo nombre) y **Actualizar**
(pisar el plato guardado). Sin elegir ninguno, la fila se ignora. Adivinar por
el proveedor es la forma rápida de pisarle un plato que no quería tocar.

**Actualizar un plato con pedidos confirmados pregunta antes** si mantenerlos o
rechazarlos, igual que el formulario de editar. Si no tiene pedidos confirmados
próximos no pregunta nada.

**Actualizar no despublica.** Como la planilla no trae agenda, una actualización
sin más le sacaría al plato la que ya tenía. La vista previa trae la agenda
vigente de cada plato guardado y la devuelve tal cual, salvo que el proveedor la
cambie al editarlo.

**Antes de importar se muestra una vista previa** con una tarjeta por plato: qué
va a pasar con cada uno, el motivo de cada error y las acciones disponibles.
Importar directo sobre la base, sin que el proveedor vea qué entendió el
sistema, es la forma rápida de arruinarle el menú de la semana.

**Límites: 5 MB por archivo y 200 filas.** Son holgados para un menú y evitan
que una planilla enorme ocupe la memoria del servidor, hoy de 1,9 GB compartidos
con todo lo demás.

# El formato

Una fila por plato. Los nombres de columna van en minúscula y sin tildes, y su
orden no importa. Las filas que empiezan con `#` son ayuda y no se importan.

| Columna | Obligatoria | Contenido |
|---|---|---|
| `nombre` | sí | Nombre del plato |
| `descripcion` | sí | Descripción que ve el empleado |
| `precio` | sí | Número mayor que cero, sin símbolo de moneda |
| `opciones_1` … `opciones_10` | no | Un grupo de opciones por columna |

Las columnas `nombre`, `descripcion` y `precio` tienen que estar: si falta
alguna, la planilla no se lee. Dos filas con el mismo nombre **no** son un
error: son dos platos que se llaman igual, que es algo que la aplicación ya
permite y que «Duplicar» crea a propósito.

La plantilla está en [`public/plantillas/menu.csv`](../public/plantillas/menu.csv)
y se abre con Excel, Google Sheets o LibreOffice.

## Grupos de opciones

**Cada columna `opciones_N` lleva un grupo**, con las opciones separadas por
coma, igual que en el formulario de la aplicación:

```
Proteína*=carne, pollo
```

- Lo que va antes del `=` es el nombre del grupo; lo que va después, sus opciones.
- **El asterisco después del nombre vuelve obligatorio el grupo**: el empleado
  tiene que elegir una opción para poder pedir el plato. Sin asterisco, elegir
  es opcional.
- Las columnas que no se usan se dejan vacías; no hace falta completarlas en
  orden ni todas.
- Las opciones no pueden repetirse dentro de un grupo, sin importar mayúsculas.
- **El empleado elige una opción por grupo.** La planilla no pregunta el límite
  para no pedir una columna más: si un grupo admite varias, se ajusta editando
  el plato, donde el grupo se ve entero.

Se eligió un grupo por columna, y no todos los grupos en una sola celda
separados por `;`, porque el separador extra era la principal fuente de errores
de tipeo y dejaba el mensaje de error difícil de explicar.

# Los estados de la vista previa

Cada fila de la planilla es una tarjeta, y cada tarjeta está en uno de cuatro
estados. El estado sale de lo que trae la fila y de lo que el proveedor decidió;
se recalcula en cada cambio, así que editarle el nombre a un plato lo puede
pasar de nuevo a existente, o al revés.

| Estado | Cuándo | Acciones | ¿Frena la importación? |
|---|---|---|---|
| Nuevo | El nombre no coincide con ningún plato guardado | Quitar · Editar | No |
| Error | Falta algo para poder crearlo | Quitar · Editar | **Sí** |
| Ya existe | El nombre coincide y todavía no decidió nada | Editar · Duplicar · Actualizar | No: se ignora |
| Actualizado | Eligió pisar el plato guardado | Quitar · Editar · Reestablecer | No |

«Editar» abre el mismo formulario que crear un plato a mano
—[`MenuForm`](../app/javascript/components/menus/new-menu-form.tsx)— en modo
local: valida igual, pero en vez de guardar devuelve el borrador. Como el
formulario no deja guardar un plato incompleto, corregirlo ahí limpia el error
de la fila.

# Cómo se traduce a los modelos

Cada entrada se convierte en los mismos atributos que arma el formulario de
crear un plato y se guarda llamando a
[`Menus::Create`](../app/services/menus/create.rb) o
[`Menus::Update`](../app/services/menus/update.rb). La importación **no escribe
en la base por su cuenta**: así hereda las validaciones, el cuidado de lo que ya
está publicado y la programación sin duplicar nada.

| Planilla | Modelo |
|---|---|
| `nombre`, `descripcion`, `precio` | `Menu` |
| `opciones_N` | Un `MenuOptionGroup` por columna (`name`, `options`, `required`, `limit`) |
| — | La agenda: `none` salvo que el proveedor le ponga días al editar el plato |

Al actualizar, los grupos de opciones se cruzan por nombre con los que el plato
ya tenía. El que coincide conserva su id —los pedidos ya hechos cruzan con ese
id la opción que eligió el empleado— y el que la importación no trae se borra.

# Las piezas

| Clase | Qué hace |
|---|---|
| [`Menus::Import::Sheet`](../app/services/menus/import/sheet.rb) | Abre el archivo con roo y devuelve una fila por plato, con el número de línea |
| [`Menus::Import::Row`](../app/services/menus/import/row.rb) | Traduce la fila a los atributos del plato y valida lo que se explica con la fila a la vista |
| [`Menus::Import::Plan`](../app/services/menus/import/plan.rb) | Junta las filas con sus errores y los problemas del archivo entero |
| [`Menus::Import::Preview`](../app/services/menus/import/preview.rb) | Arma la vista previa tal como la consume la pantalla |
| [`Menus::Import::SavedMenus`](../app/services/menus/import/saved_menus.rb) | Los platos guardados del proveedor, con sus pedidos confirmados y su agenda |
| [`Menus::Import::Save`](../app/services/menus/import/save.rb) | Guarda la lista revisada en una transacción, con `Menus::Create` o `Menus::Update` |
| [`Provider::MenuImportsController`](../app/controllers/provider/menu_imports_controller.rb) | Los dos pasos: `create` lee la planilla y `confirm` guarda lo revisado |
| [`menu_imports/new.tsx`](../app/javascript/pages/provider/menu_imports/new.tsx) | La pantalla: descargar la plantilla y subirla |
| [`import/review.tsx`](../app/javascript/components/menus/import/review.tsx) | La revisión: las tarjetas, sus acciones y el envío |
| [`lib/menu-import.ts`](../app/javascript/lib/menu-import.ts) | Los estados, el cruce por nombre y lo que se manda al confirmar |

Se entra desde «Importar platos», en Publicar menú. El primer paso devuelve la
planilla leída; el navegador la sostiene mientras el proveedor la revisa y el
segundo paso manda **la lista revisada**, no el archivo. Así la planilla no
queda guardada en el servidor entre uno y otro, y editar una fila no cuesta un
viaje de ida y vuelta.

La vista previa viene con un `id` que cambia con cada archivo subido: la pantalla
monta la revisión con esa clave, de modo que subir otra planilla descarta lo que
se venía revisando sin que haga falta sincronizar nada a mano.

# Notas de la implementación

**`roo` descarta la primera fila si se usa `parse` sin argumentos**, porque la
toma como encabezado. Comprobado: un archivo de tres líneas devuelve dos. Por
eso `Sheet` lee fila por fila sobre `first_row..last_row`, descarta las vacías y
las que empiezan con `#`, y recién ahí toma la primera fila restante como
encabezado. Así el archivo tolera filas de ayuda, títulos y líneas en blanco
arriba.

**Excel guarda los CSV con un BOM al principio.** Sin sacarlo, el primer
encabezado no sería `nombre` y la planilla parecería incompleta, con un mensaje
que habla de una columna que está a la vista. `Sheet` lo saca al normalizar los
encabezados, y la plantilla lo lleva para que Excel le respete los acentos.

**Las filas de ayuda van entre comillas, y sin comillas adentro.** Se descartan
después de parsear, así que afectan la lectura dos veces: una comilla doble
suelta rompe el archivo entero con `CSV::MalformedCSVError`, y una coma sin
comillas parte el comentario en varias celdas, que es cómo Excel se lo muestra
al proveedor y se ve como un error de la plantilla.

**Una celda con comas va entre comillas en CSV.** Excel y Google Sheets las
agregan solas al guardar; solo importa si alguien edita el archivo a mano en un
editor de texto.

**El id del plato a actualizar llega del navegador**, así que `Save` lo vuelve a
buscar entre los platos del proveedor: una lista manipulada no alcanza para
tocar el menú de otro.

# Qué falta decidir

- **La plantilla descargable es un `.csv`.** Para un `.xlsx` con formato, hoja
  de instrucciones y listas desplegables hace falta `caxlsx` y un endpoint que
  lo genere.
- **No se puede importar una variante de un plato.** Las variantes por rango de
  fechas siguen saliendo del formulario de editar.
- **Quitar todas las tarjetas deja la pantalla vacía**, con el botón apagado. Se
  vuelve a empezar con el tacho de arriba.
