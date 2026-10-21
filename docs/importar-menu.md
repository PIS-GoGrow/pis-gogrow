# Importar un menú desde una planilla

El proveedor arma su menú en una planilla y la sube desde **Publicar menú** en
lugar de cargar los platos uno por uno. Este documento define el formato del
archivo, las decisiones que lo rodean y cómo se traduce a los modelos.

Ítem relacionado: IBP-052.

# Qué se decidió

**Formatos aceptados: `.xlsx`, `.csv` y `.ods`.** El `.xls` anterior a 2007
queda afuera: necesita otra biblioteca y hoy casi no se usa.

**La lectura la hace la gema [roo](https://github.com/roo-rb/roo).** Lee los
tres formatos con la misma interfaz, está mantenida y es la más usada del
ecosistema por un margen amplio. Se descartaron `creek`, sin mantenimiento
desde 2023, y `rubyXL`, de interfaz más incómoda. `caxlsx` resuelve el problema
contrario, escribir planillas, y haría falta solo si algún día la aplicación
genera una plantilla `.xlsx`.

**Un plato que ya existe se actualiza, no se duplica.** La coincidencia es por
nombre, entre los platos guardados del proveedor. Si cambió el precio o la
descripción, quedan los valores de la planilla.

**La importación es todo o nada.** Si una sola fila tiene un error, no se crea
ni se modifica nada. Es más fácil de entender para quien importa y no deja el
menú a medio cargar; el precio es que un error de tipeo obliga a corregir y
volver a subir.

**Antes de confirmar se muestra una vista previa** con lo que se va a crear, lo
que se va a actualizar, y los errores con el número de fila y el motivo.
Importar directo sobre la base, sin que el proveedor vea qué entendió el
sistema, es la forma rápida de arruinarle el menú de la semana.

**Límites: 2 MB por archivo y 200 filas.** Son holgados para un menú semanal y
evitan que una planilla enorme ocupe la memoria del servidor, hoy de 1,9 GB
compartidos con todo lo demás.

# El formato

Una fila por plato. Los nombres de columna van en minúscula y sin tildes, y su
orden no importa. Las filas que empiezan con `#` son ayuda y no se importan.

| Columna | Obligatoria | Contenido |
|---|---|---|
| `nombre` | sí | Nombre del plato |
| `descripcion` | sí | Descripción que ve el empleado |
| `precio` | sí | Número mayor que cero, sin símbolo de moneda |
| `cupo` | sí | Porciones disponibles por día |
| `lunes` … `viernes` | al menos una | `x` en los días en que se ofrece |
| `desde` | no | Primer día que se programa (`AAAA-MM-DD`). Por defecto, el lunes de la semana próxima |
| `hasta` | no | Último día que se programa. Vacío significa sin fecha de fin |
| `limite` | no | Cuántas opciones puede elegir el empleado en cada grupo. Vacío es 1 |
| `opciones_1` … `opciones_10` | no | Un grupo de opciones por columna |

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
- **El límite sale de la columna `limite`** y vale para todos los grupos del
  plato. Un plato con dos grupos de límites distintos —elegí 1 proteína y hasta
  3 agregados— no se puede expresar: se importa con el mismo límite en ambos y
  se corrige editando el plato. Si ese caso aparece seguido, la salida sin
  agregar columnas es ponerlo en la celda, `Agregados*3=panceta, huevo`.

Se eligió un grupo por columna, y no todos los grupos en una sola celda
separados por `;`, porque el separador extra era la principal fuente de errores
de tipeo y dejaba el mensaje de error difícil de explicar.

# Cómo se traduce a los modelos

Cada fila se convierte en los mismos atributos que arma el formulario de crear
un plato y se guarda llamando a [`Menus::Create`](../app/services/menus/create.rb).
La importación **no escribe en la base por su cuenta**: así hereda las
validaciones, el archivado de platos y la programación sin duplicar nada.

| Planilla | Modelo |
|---|---|
| `nombre`, `descripcion`, `precio` | `Menu` |
| `opciones_N` | Un `MenuOptionGroup` por columna (`name`, `options`, `required`, `limit`) |
| Días marcados, `cupo`, `desde`, `hasta` | La agenda: `weekly` sin `hasta`, `range` con `hasta` |

# Notas para quien lo implemente

**`roo` descarta la primera fila si se usa `parse` sin argumentos**, porque la
toma como encabezado. Comprobado: un archivo de tres líneas devuelve dos. Hay
que leer fila por fila sobre `first_row..last_row` con `row(i)`, descartar las
vacías y las que empiezan con `#`, y recién ahí tomar la primera fila restante
como encabezado. Así el archivo tolera filas de ayuda, títulos y líneas en
blanco arriba.

**Las filas de ayuda van entre comillas, y sin comillas adentro.** Se descartan
después de parsear, así que afectan la lectura dos veces: una comilla doble
suelta rompe el archivo entero con `CSV::MalformedCSVError`, y una coma sin
comillas parte el comentario en varias celdas, que es cómo Excel se lo muestra
al proveedor y se ve como un error de la plantilla.

**Una celda con comas va entre comillas en CSV.** Excel y Google Sheets las
agregan solas al guardar; solo importa si alguien edita el archivo a mano en un
editor de texto.

# Qué falta decidir

- **La plantilla descargable es un `.csv`.** Para un `.xlsx` con formato, hoja
  de instrucciones y listas desplegables hace falta `caxlsx` y un endpoint que
  lo genere.
- **Límites distintos por grupo en un mismo plato** no se pueden expresar.
- **Las variantes de un plato** (el mismo plato con otro precio para ciertas
  fechas) tampoco: la importación crea o actualiza el plato guardado.
