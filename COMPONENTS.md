# Componentes de UI

Catálogo oficial de los componentes de interfaz de este repositorio. Lo usan el equipo y cualquier agente de IA que cree o modifique pantallas.

Reúne dos fuentes: los componentes que ya existían acá (del starter kit y de las primeras features) y el catálogo del prototipo en React que armó el equipo. Cuando los dos resolvían lo mismo de forma distinta, la decisión está en [Superposiciones con el prototipo](#superposiciones-con-el-prototipo).

## Decisión de base: se mantiene el sistema de este repo

El prototipo y este repo parten de shadcn/ui, pero con configuraciones incompatibles:

| | Prototipo | Este repo |
|---|---|---|
| Estilo de shadcn | `base-nova` | `new-york` ([`components.json`](components.json)) |
| Primitivos | [Base UI](https://base-ui.com) | [Radix](https://www.radix-ui.com) (paquete `radix-ui`) |
| Estilos | CSS Modules con tokens del tema | Clases de Tailwind v4 con los mismos tokens (`bg-primary`, `border-input`…) |
| Ubicación | `components/ui/<categoría>/<componente>.tsx` | `components/ui/<componente>.tsx` |
| `Select` y `RadioGroup` | Elementos HTML nativos | Primitivos de Radix |

**Se usa el sistema de este repo.** Ya lo usan todas las pantallas existentes, es la convención del starter kit y de la skill `shadcn-inertia`, y `AGENTS.md` trata `components/ui/` como código generado por el CLI de shadcn, que se agrega y no se edita a mano. Adoptar el del prototipo implicaría sumar una segunda librería de primitivos y reescribir lo que ya funciona.

Del prototipo se reutiliza **qué componente corresponde a cada caso y cómo se combina**, no su código ni su CSS. Al portar una pantalla del prototipo hay que reescribir imports y estilos según este archivo: la API válida es la que figura acá, no la del prototipo ni la de un ejemplo suelto de la documentación de shadcn.

## Reglas

1. **Si el componente está en la lista, se usa el de la lista.** No se recrea con `<button>`, `<input>`, `<select>` o `<div>` estilizados a mano.
2. **Si se necesita un componente que no está en la lista, se agrega a la lista.** Se incorpora siguiendo [Agregar un componente](#agregar-un-componente) y se documenta en este archivo, en el mismo commit. No se crean versiones propias dentro de `pages/` o de la carpeta de una feature.
3. Se importa desde `@/components/ui/<componente>`. Las pantallas no importan `radix-ui` directamente.
4. **Los archivos de `components/ui/` no se editan a mano.** Para adaptar la apariencia en una pantalla se usa `className` con clases de Tailwind; `cn()` resuelve los conflictos con las clases base.
5. Si la misma personalización se repite en dos o más lugares, se convierte en un componente compartido en `components/` (fuera de `ui/`) que envuelve al primitivo, y se registra en [Componentes propios](#componentes-propios-components).
6. Íconos: `lucide-react`. Los decorativos llevan `aria-hidden="true"`; los botones que sólo muestran un ícono llevan `aria-label`.
7. No se incorporan otras librerías de componentes (MUI, Chakra, Base UI, Headless UI, etc.). `@headlessui/react` ya está instalado, pero sólo lo usan pantallas de la plantilla (ver [pendientes](#patrones-de-este-repo-que-todavía-no-siguen-la-lista)); no se amplía su uso.
8. Formularios: Inertia `<Form>` (o `useForm`) con `Field` e `Input` conectados por `name`. Nunca `react-hook-form` ni los `FormField`/`FormItem`/`FormMessage` de shadcn.

## Lista de componentes

### Primitivos instalados (`components/ui/`)

| Componente | Importar desde | Usar para |
|---|---|---|
| `Button`, `buttonVariants` | `@/components/ui/button` | Toda acción clickeable y enlaces con aspecto de botón |
| `Badge`, `badgeVariants` | `@/components/ui/badge` | Estados (pendiente, confirmado…) y etiquetas breves |
| `Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardAction`, `CardContent`, `CardFooter` | `@/components/ui/card` | Superficies: ítems de lista, métricas, formularios, resúmenes |
| `Alert`, `AlertTitle`, `AlertDescription` | `@/components/ui/alert` | Errores, avisos y confirmaciones dentro de la pantalla |
| `Field`, `FieldLabel`, `FieldError`, `FieldDescription`, `FieldGroup`, `FieldSet`, `FieldLegend`, `FieldContent`, `FieldTitle`, `FieldSeparator` | `@/components/ui/field` | Estructura de formularios: etiqueta, ayuda, error, grupos, divisor con texto |
| `Input` | `@/components/ui/input` | Texto, email, número, fecha, búsqueda, archivo |
| `Label` | `@/components/ui/label` | Etiqueta suelta fuera de un `Field` |
| `Checkbox` | `@/components/ui/checkbox` | Selección múltiple o casilla sí/no |
| `Select`, `SelectTrigger`, `SelectValue`, `SelectContent`, `SelectItem`, `SelectGroup`, `SelectLabel`, `SelectSeparator` | `@/components/ui/select` | Elegir una opción de una lista |
| `ToggleGroup`, `ToggleGroupItem`, `Toggle` | `@/components/ui/toggle-group`, `@/components/ui/toggle` | Filtros, días, control segmentado |
| `Separator` | `@/components/ui/separator` | Divisores horizontales o verticales |
| `Dialog`, `DialogTrigger`, `DialogContent`, `DialogHeader`, `DialogTitle`, `DialogDescription`, `DialogFooter`, `DialogClose` | `@/components/ui/dialog` | Confirmaciones y formularios cortos sobre la pantalla |
| `Sheet`, `SheetTrigger`, `SheetContent`, `SheetHeader`, `SheetTitle`, `SheetDescription`, `SheetFooter`, `SheetClose` | `@/components/ui/sheet` | Paneles que entran desde un borde (detalle, carrito en móvil) |
| `DropdownMenu` y sus partes | `@/components/ui/dropdown-menu` | Menú de acciones secundarias |
| `Tooltip`, `TooltipTrigger`, `TooltipContent` | `@/components/ui/tooltip` | Texto de ayuda breve al pasar el mouse o enfocar |
| `Collapsible`, `CollapsibleTrigger`, `CollapsibleContent` | `@/components/ui/collapsible` | Contenido que se expande y contrae |
| `Avatar`, `AvatarImage`, `AvatarFallback`, `AvatarBadge`, `AvatarGroup` | `@/components/ui/avatar` | Foto o iniciales de una persona |
| `Empty`, `EmptyHeader`, `EmptyMedia`, `EmptyTitle`, `EmptyDescription`, `EmptyContent` | `@/components/ui/empty` | Estado vacío de una lista o sección |
| `Skeleton` | `@/components/ui/skeleton` | Espacio reservado mientras carga contenido |
| `Spinner` | `@/components/ui/spinner` | Indicador de acción en curso (dentro de un botón) |
| `Toaster` | `@/components/ui/sonner` | Ya montado en `PersistentLayout`; no se vuelve a montar |

`Sidebar`, `NavigationMenu` y `Breadcrumb` también están en `components/ui/`, pero los usa el layout. Las pantallas no los usan directamente: ver [AppLayout y navegación](#applayout-y-navegación).

### Primitivos a agregar cuando se necesiten

Los usa el prototipo y todavía no están instalados. Se agregan con el CLI la primera vez que una pantalla los necesite; al hacerlo, la fila pasa a la tabla anterior y se escribe su sección de detalle.

| Componente | Comando | Usar para | API de shadcn (Radix) |
|---|---|---|---|
| `Textarea` | `add textarea` | Texto multilínea | Mismas props que `<textarea>` |
| `RadioGroup`, `RadioGroupItem` | `add radio-group` | Selección única con título y descripción | `name`, `value`/`defaultValue`, `onValueChange`; ítems con `value` e `id` |
| `Switch` | `add switch` | Activar o desactivar una opción | `checked`, `onCheckedChange`, `name` |
| `Tabs`, `TabsList`, `TabsTrigger`, `TabsContent` | `add tabs` | Alternar entre paneles de contenido | `defaultValue`/`value`; `TabsTrigger` y `TabsContent` con el mismo `value` |
| `Progress` | `add progress` | Barra de progreso (beneficio usado, pedidos por proveedor) | `value` de 0 a 100 |

### Componentes propios (`components/`)

| Componente | Importar desde | Usar para |
|---|---|---|
| `AppLayout` | `@/layouts/app-layout` | Toda pantalla con sesión iniciada; recibe `breadcrumbs` |
| `Heading` | `@/components/heading` | Encabezado de pantalla: título y descripción opcional |
| `HeadingSmall` | `@/components/heading-small` | Encabezado de sección dentro de una pantalla |
| `AlertError` | `@/components/alert-error` | `Alert` destructivo con una lista de errores |
| `TextLink` | `@/components/text-link` | Enlace de texto dentro de un párrafo (usa `Link` de Inertia) |
| `UserInfo` | `@/components/user-info` | Avatar con nombre y, opcionalmente, email |
| `useInitials` | `@/hooks/use-initials` | Iniciales para `AvatarFallback` |
| `Icon` | `@/components/icon` | Renderizar un ícono de lucide recibido como prop |
| `GoogleMark` | `@/components/branding/google-mark` | Logo de Google en el acceso con Google |

`PlaceholderPattern` sólo rellena los dashboards que todavía no están hechos. No se usa en pantallas nuevas.

### Propios a crear

El prototipo repite estos patrones en varias pantallas. Acá no existen: se crean como componente compartido al portar la primera pantalla que los use, y su fila pasa a la tabla anterior.

| Componente | Archivo | Cómo se arma |
|---|---|---|
| `Stat` (tarjeta de métrica) | `components/stat.tsx` | `Card` compacta: etiqueta en `CardDescription`, valor y detalle en `CardContent` |
| `QuantityInput` (− / número / +) | `components/quantity-input.tsx` | Dos `Button variant="outline" size="icon-sm"` con `aria-label` («Quitar uno», «Agregar uno») y el número en el medio |
| `StatusBadge` | `components/status-badge.tsx` | `Badge variant="outline"` con `data-status` y un mapa de estado a clases de color |

## Superposiciones con el prototipo

| Componente o patrón | En el prototipo | En este repo | Qué se usa |
|---|---|---|---|
| `Button` | `actions/button`; enlace con `buttonVariants` | `button`, mismas variantes y tamaños; `asChild` | El del repo |
| `Badge` | Prop `render` | Mismas variantes; `asChild` en lugar de `render` | El del repo |
| `Card` | `size="sm"`; `CardFooter` con borde y fondo | Sin `size`; `CardFooter` sin borde | El del repo; la versión compacta se arma con `className` |
| `Alert` | Incluye `AlertAction` | Sin `AlertAction` | El del repo |
| `Checkbox`, `Input`, `Label`, `Separator` | Misma API | Misma API | Los del repo |
| `Select` | `<select>` nativo con `<option>` y `onChange` | Radix con `SelectTrigger`, `SelectItem` y `onValueChange` | **El del repo.** La advertencia del prototipo se invierte: acá la API nativa es la que no existe |
| `RadioGroup` / `RadioOption` | Radios nativos con `label` y `description` | No instalado | `radio-group` de shadcn; la opción con título y descripción se arma con `Field` |
| `Textarea` | Instalado | No instalado | `textarea` de shadcn |
| Filtros, días, control segmentado | `Button` con `aria-pressed` y `data-selected` | `ToggleGroup` | `ToggleGroup` |
| Divisor con texto | Dos `Separator` y un `<span>` | `FieldSeparator` con texto | `FieldSeparator` |
| `Avatar`, `Empty`, `Collapsible`, mensaje temporal | Pendientes de agregar | Instalados | Los del repo |
| `Tabs`, `Switch`, `Progress` | Pendientes de agregar | No instalados | Los de shadcn, cuando se necesiten |
| Encabezado de sección (`Header`, `ScreenHeader`) | Duplicado en cuatro pantallas | `Heading`, `HeadingSmall` | Los del repo |
| Navegación lateral y barra inferior | Una por dashboard | `AppLayout` con sidebar por rol | `AppLayout` |
| Mensaje temporal | `styles.toast` con `setTimeout` | Flash del servidor que muestra Sonner | Flash del servidor |
| `Stat`, control de cantidad, colores de estado | Duplicados | No existen | [Propios a crear](#propios-a-crear) |
| `GoogleMark` | `branding/google-mark` | Igual | El mismo |

## Detalle por componente

### Button

```tsx
import { Button, buttonVariants } from "@/components/ui/button"
```

| Prop | Valores | Por defecto |
|---|---|---|
| `variant` | `default` · `outline` · `secondary` · `ghost` · `destructive` · `link` | `default` |
| `size` | `default` · `xs` · `sm` · `lg` · `icon` · `icon-xs` · `icon-sm` · `icon-lg` | `default` |
| `asChild` | Renderiza el hijo (por ejemplo, un `Link`) con los estilos del botón | `false` |

Acepta todas las props de un `<button>` (`onClick`, `disabled`, `type`…).

| Caso | Cómo se resuelve |
|---|---|
| Acción principal | `variant="default"`; `size="lg"` para la acción principal de la pantalla |
| Acción secundaria o cancelar | `variant="outline"` |
| Acción terciaria dentro de una tarjeta («Editar», «Ver todos») | `variant="ghost" size="sm"` |
| Acción que borra o no se puede deshacer | `variant="destructive"` |
| Botón con ícono solo | `size="icon"` + `aria-label` |
| Acción en curso | `disabled={processing}` y `{processing && <Spinner />}` antes del texto |
| Enlace con aspecto de botón | `<Button asChild><Link href={…}>…</Link></Button>` |
| Opción seleccionable (filtros, días, proveedores) | No es un `Button`: se usa [`ToggleGroup`](#togglegroup) |

```tsx
<Button asChild variant="ghost" size="sm">
  <Link href={providerMenus.show(menu.id)}>Ver</Link>
</Button>
```

### Badge

```tsx
import { Badge } from "@/components/ui/badge"
```

| Prop | Valores | Por defecto |
|---|---|---|
| `variant` | `default` · `secondary` · `destructive` · `outline` · `ghost` · `link` | `default` |
| `asChild` | Renderiza el hijo (por ejemplo, un `Link`) con los estilos del badge | `false` |

- Etiqueta informativa («Este mes», fecha de entrega): `variant="secondary"`.
- Estado de un pedido o pago: `StatusBadge` (ver [Propios a crear](#propios-a-crear)). Mientras no exista, `variant="outline"` con las clases de color en `className`, y al segundo uso se crea el componente.

### Card

```tsx
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
```

- `Card` sólo tiene padding vertical (`py-6`) y separa sus partes con `gap-6`. El padding horizontal lo agregan `CardHeader`, `CardContent` y `CardFooter`: el contenido puesto directamente dentro de `Card` queda pegado a los bordes.
- No hay prop `size`. Para ítems de lista y métricas se compacta con `className`, como en el ejemplo. Si la misma tarjeta compacta aparece en dos lugares, se extrae (por ejemplo, `Stat` o [`MenuCard`](app/javascript/components/menus/menu-card.tsx)).
- `CardTitle` renderiza un `<div>`. Si el título debe ser un encabezado del documento, usar `<h2>`/`<h3>` dentro de `CardHeader`.
- `CardAction` va dentro de `CardHeader` y se ubica arriba a la derecha.
- `CardFooter` no trae borde. Con `className="border-t"` se le agrega el borde y el espacio superior.

```tsx
<Card className="gap-3 py-4">
  <CardHeader className="px-4">
    <CardDescription>Pedidos de hoy</CardDescription>
  </CardHeader>
  <CardContent className="px-4">
    <strong className="text-2xl">7</strong>
    <p className="text-sm text-muted-foreground">2 por confirmar</p>
  </CardContent>
</Card>
```

### Alert

```tsx
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
```

| Prop | Valores | Por defecto |
|---|---|---|
| `variant` | `default` · `destructive` | `default` |

- Tiene `role="alert"`, que los lectores de pantalla anuncian de inmediato. Para confirmaciones no urgentes, pasar `role="status"`.
- Un ícono (`<svg>`) como hijo directo ocupa su propia columna.
- No hay `AlertAction`. Si hace falta un botón, va dentro de `AlertDescription`.
- Para mostrar varios errores juntos, `AlertError` ya arma la lista.

```tsx
<Alert variant="destructive">
  <AlertCircleIcon aria-hidden="true" />
  <AlertTitle>No pudimos iniciar sesión</AlertTitle>
  <AlertDescription>{errors.auth}</AlertDescription>
</Alert>
```

### Field, Input y Label

```tsx
import { Field, FieldDescription, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
```

Cada control de formulario va dentro de un `Field`:

- `FieldLabel` con `htmlFor` igual al `id` del control.
- El control con `name`, que es lo que conecta el valor con `<Form>` de Inertia.
- `FieldDescription` para el texto de ayuda y `FieldError` para los errores. No se muestran errores con `FieldDescription`.
- Con error: `data-invalid` en el `Field` (pinta etiqueta y texto) y `aria-invalid` en el control (pinta el borde).
- `Field orientation="horizontal"` pone el control al lado de la etiqueta (checkbox, switch). `FieldGroup` apila varios `Field`, y `FieldSet` con `FieldLegend` agrupa opciones bajo un título.

`Input` acepta las mismas props que `<input>` y sirve para cualquier `type`. `Label` sólo se usa suelto, fuera de un `Field`.

```tsx
<Form action={providerMenus.create()}>
  {({ errors, processing }) => (
    <FieldGroup>
      <Field data-invalid={!!errors.name}>
        <FieldLabel htmlFor="name">Nombre</FieldLabel>
        <Input id="name" name="name" aria-invalid={!!errors.name} />
        <FieldError errors={errors.name?.map((message) => ({ message }))} />
      </Field>

      <Field>
        <FieldLabel htmlFor="price">Precio</FieldLabel>
        <Input id="price" name="price" type="number" min="0" step="0.01" />
        <FieldDescription>Precio por porción.</FieldDescription>
      </Field>

      <Button type="submit" disabled={processing}>
        {processing && <Spinner />}
        Crear
      </Button>
    </FieldGroup>
  )}
</Form>
```

Para un divisor con texto (por ejemplo, «o» entre dos formas de ingresar) se usa `<FieldSeparator>o</FieldSeparator>`.

### Checkbox

```tsx
import { Checkbox } from "@/components/ui/checkbox"
```

Basado en Radix: se controla con `checked` y `onCheckedChange`, **no** con `onChange`. `onCheckedChange` puede recibir `"indeterminate"`, por eso se compara con `true`. Con `name` envía su valor dentro de un `<Form>`.

```tsx
<Field orientation="horizontal">
  <Checkbox
    id="remember"
    name="remember"
    checked={remember}
    onCheckedChange={(checked) => setRemember(checked === true)}
  />
  <FieldLabel htmlFor="remember">Mantener mi sesión iniciada</FieldLabel>
</Field>
```

### Select

```tsx
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
```

Es el `Select` de Radix, **no** un `<select>` nativo: las opciones son `SelectItem` y el cambio se lee con `onValueChange`, que recibe el valor directamente. La API del prototipo (`<option>`, `onChange`, `event.target.value`) no existe acá.

- **`name` es obligatorio dentro de un `<Form>`**: sin él, el valor no se envía. Los ejemplos de shadcn lo omiten.
- Los valores son strings: los ids se pasan con `String(id)`.
- `SelectItem` no acepta `value=""`. La opción «sin elegir» se muestra con `placeholder` en `SelectValue`.
- `SelectTrigger` ocupa lo que su contenido por defecto; en formularios se le pasa `className="w-full"`.
- Si hace falta buscar dentro de la lista, es otro componente (`Combobox`) y se agrega a la lista.

```tsx
<Field>
  <FieldLabel htmlFor="provider">Proveedor</FieldLabel>
  <Select name="provider_id">
    <SelectTrigger id="provider" className="w-full">
      <SelectValue placeholder="Elegí un proveedor" />
    </SelectTrigger>
    <SelectContent>
      {providers.map((provider) => (
        <SelectItem key={provider.id} value={String(provider.id)}>
          {provider.name}
        </SelectItem>
      ))}
    </SelectContent>
  </Select>
</Field>
```

### ToggleGroup

```tsx
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
```

Reemplaza los botones con `aria-pressed` del prototipo para filtros, días y el control segmentado de proveedores. Radix se encarga de los atributos ARIA y de la navegación con flechas, así que no se agregan a mano.

| Prop | Valores | Por defecto |
|---|---|---|
| `type` | `single` (una opción) · `multiple` (varias) | — (obligatoria) |
| `variant` | `default` · `outline` | `default` |
| `size` | `default` · `sm` · `lg` | `default` |
| `spacing` | Separación entre ítems; `0` los une como control segmentado | `0` |

- Con `type="single"`, volver a tocar la opción activa la deselecciona y `onValueChange` recibe `""`. Si siempre tiene que haber una opción elegida, ignorar ese valor, como en el ejemplo.
- Con `type="multiple"` (por ejemplo, días de la semana), `value` es un `string[]`.
- No envía valores en un `<Form>`: sirve para estado de la pantalla (filtrar una lista). Para elegir un valor de formulario se usa `RadioGroup` o `Select`.
- Si se cambia de panel de contenido y no se filtra la misma lista, corresponde `Tabs`.

```tsx
<ToggleGroup
  type="single"
  variant="outline"
  size="sm"
  value={filter}
  onValueChange={(value) => value && setFilter(value)}
>
  <ToggleGroupItem value="pending">Pendientes</ToggleGroupItem>
  <ToggleGroupItem value="confirmed">Confirmados</ToggleGroupItem>
</ToggleGroup>
```

### RadioGroup (a agregar)

Cuando se instale con `add radio-group`, la opción con título y descripción del prototipo (`RadioOption`) se arma combinando `RadioGroupItem` con `Field`. No se crea un `RadioOption` propio.

```tsx
<FieldSet>
  <FieldLegend variant="label">Entrega</FieldLegend>
  <RadioGroup name="delivery" defaultValue="office">
    <FieldLabel htmlFor="delivery-office">
      <Field orientation="horizontal">
        <FieldContent>
          <FieldTitle>Oficina</FieldTitle>
          <FieldDescription>18 de Julio 1006</FieldDescription>
        </FieldContent>
        <RadioGroupItem value="office" id="delivery-office" />
      </Field>
    </FieldLabel>
  </RadioGroup>
</FieldSet>
```

### Separator

```tsx
import { Separator } from "@/components/ui/separator"
```

| Prop | Valores | Por defecto |
|---|---|---|
| `orientation` | `horizontal` · `vertical` | `horizontal` |

Para un divisor con texto se usa `FieldSeparator` (ver [Field](#field-input-y-label)).

### Dialog

```tsx
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
```

- Siempre lleva `DialogTitle` (lo leen los lectores de pantalla y Radix avisa en consola si falta) y, si hay texto explicativo, `DialogDescription`.
- Para cerrarlo al terminar una acción del servidor, se controla con `open` y `onOpenChange`, y se cierra en `onSuccess` (ver [`delete-menu-dialog.tsx`](app/javascript/components/menus/delete-menu-dialog.tsx)).
- El botón de cancelar se escribe con `DialogClose asChild`. `DialogFooter showCloseButton` muestra un texto en inglés («Close»), así que no se usa.

```tsx
<Dialog open={open} onOpenChange={setOpen}>
  <DialogTrigger asChild>
    <Button variant="outline" size="sm">Borrar</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>¿Borrar «{menu.name}»?</DialogTitle>
      <DialogDescription>Esta acción no se puede deshacer.</DialogDescription>
    </DialogHeader>
    <DialogFooter>
      <DialogClose asChild>
        <Button variant="outline">Cancelar</Button>
      </DialogClose>
      <Button variant="destructive" disabled={processing} onClick={handleDelete}>
        {processing && <Spinner />}
        Borrar
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### Sheet

```tsx
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet"
```

Mismo patrón que `Dialog`, pero entra desde un borde: `side` en `SheetContent` acepta `top`, `right` (por defecto), `bottom` o `left`. También exige `SheetTitle`. El sidebar ya lo usa en móvil, así que no hace falta para la navegación.

### Avatar

```tsx
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useInitials } from "@/hooks/use-initials"
```

| Prop (en `Avatar`) | Valores | Por defecto |
|---|---|---|
| `size` | `sm` · `default` · `lg` | `default` |

`AvatarFallback` se muestra mientras carga la imagen o si no hay imagen. Para avatar con nombre, usar `UserInfo`.

```tsx
const getInitials = useInitials()

<Avatar size="lg">
  <AvatarImage src={user.avatar} alt={user.name} />
  <AvatarFallback>{getInitials(user.name)}</AvatarFallback>
</Avatar>
```

### Empty

```tsx
import { Empty, EmptyContent, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
```

`EmptyMedia variant="icon"` muestra el ícono dentro de un recuadro; con `default` se muestra sin fondo.

```tsx
<Empty>
  <EmptyHeader>
    <EmptyMedia variant="icon">
      <Utensils aria-hidden="true" />
    </EmptyMedia>
    <EmptyTitle>No hay platos aún</EmptyTitle>
    <EmptyDescription>Creá el primero para poder publicar tu menú.</EmptyDescription>
  </EmptyHeader>
  <EmptyContent>
    <Button>Agregar plato</Button>
  </EmptyContent>
</Empty>
```

### Mensajes temporales (Sonner)

El `Toaster` ya está montado en [`PersistentLayout`](app/javascript/layouts/persistent-layout.tsx) y `useFlash` muestra automáticamente el flash de cada respuesta. Por eso, **después de una acción del servidor el mensaje se manda desde el controlador**: `notice` se muestra como mensaje normal y `alert` como error.

```ruby
redirect_to provider_menus_path, notice: "Plato creado"
```

Sólo para un mensaje que no depende del servidor (por ejemplo, «Copiado»), se llama a `toast` desde el paquete `sonner`, no desde `@/components/ui/sonner`, que sólo exporta `Toaster`:

```tsx
import { toast } from "sonner"

toast.success("Copiado")
```

### Collapsible

```tsx
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"
```

Reemplaza los `<details>` del prototipo.

```tsx
<Collapsible>
  <CollapsibleTrigger asChild>
    <Button variant="ghost" size="sm">Ver comprobante</Button>
  </CollapsibleTrigger>
  <CollapsibleContent>…</CollapsibleContent>
</Collapsible>
```

### Spinner y Skeleton

- `Spinner` va dentro del botón que dispara la acción, antes del texto, mientras `processing` es verdadero. Ya trae `role="status"`.
- `Skeleton` reserva el lugar de contenido que todavía no llegó (por ejemplo, props diferidas de Inertia). Se le da tamaño con `className` (`h-4 w-32`).

### Heading y HeadingSmall

```tsx
import Heading from "@/components/heading"
import HeadingSmall from "@/components/heading-small"
```

Reemplazan los `Header` y `ScreenHeader` del prototipo. Ambos reciben `title` y `description` opcional. `Heading` renderiza un `<h2>` con margen inferior y va una vez por pantalla; `HeadingSmall` renderiza un `<h3>` y encabeza cada sección.

```tsx
<Heading title="Tus platos" description="Los platos que podés publicar en tu menú." />
```

### AppLayout y navegación

- Toda pantalla con sesión iniciada se envuelve en `AppLayout`, que incluye el sidebar del rol de la sesión y los breadcrumbs.
- Para agregar una sección a la navegación de un rol, se agrega un ítem a `navItems[rol]` en [`app-sidebar.tsx`](app/javascript/components/app-sidebar.tsx), con `title`, `href` (helper de `@/routes`) e `icon` de lucide. No se arma una navegación propia por dashboard.
- En móvil, el sidebar se abre como `Sheet`; eso ya lo resuelve `Sidebar`.
- La barra inferior del prototipo no existe acá. Si el equipo decide tenerla, se crea un único componente compartido que use los mismos `navItems`.

```tsx
<AppLayout breadcrumbs={[{ title: "Platos", href: providerMenus.index().url }]}>
  <Head title="Mis platos" />
  …
</AppLayout>
```

## Agregar un componente

1. **Verificar que no exista.** Revisar esta lista y `app/javascript/components/ui/`. Si se resuelve combinando componentes existentes, no hace falta uno nuevo.
2. **Agregarlo con el CLI de shadcn**, que usa la configuración de [`components.json`](components.json) (estilo `new-york`, Radix):

   ```powershell
   docker compose exec web npx shadcn@latest add <componente>
   ```

   El archivo queda directamente en `components/ui/<componente>.tsx`, listo para usar, sin mover ni adaptar nada.

   - Revisar `git status` y `package.json`: el CLI puede instalar dependencias o tocar otros archivos. Si agrega un paquete npm nuevo, justificarlo en el PR.
   - `.npmrc` rechaza versiones publicadas hace menos de 7 días (ver `AGENTS.md`). Si la instalación falla por eso, no es un error del paquete.
   - No ejecutar `add` para un componente que ya está en la lista: el CLI ofrece sobrescribirlo con otra versión.

3. **No editar el archivo generado.** ESLint y Prettier ignoran `components/ui/`. Si hace falta una variante propia, se crea un componente en `components/` que lo envuelva (regla 5).
4. **Documentarlo en este archivo**, en el mismo commit: una fila en la [lista](#lista-de-componentes) (sacándola de «a agregar», si estaba ahí) y una sección en [Detalle por componente](#detalle-por-componente).
5. **Reemplazar las implementaciones hechas a mano** de ese patrón (ver la sección siguiente) y quitar su fila. Si no se migran en ese momento, dejarlas anotadas.
6. **Verificar:** `docker compose exec -T web npm run check` y `npm run lint`, y revisar la pantalla en móvil y en escritorio.

## Patrones de este repo que todavía no siguen la lista

Relevamiento del 12/09/2026. Al migrar un patrón, borrar su fila.

| Patrón | Dónde está hoy | Qué hacer |
|---|---|---|
| Errores de campo con `FieldDescription`; `FieldLabel htmlFor` sin `id` en el `Input`; sin `aria-invalid` | [`components/menus/new-menu-form.tsx`](app/javascript/components/menus/new-menu-form.tsx) | `FieldError`, `id` en el `Input` y `aria-invalid` |
| Confirmación de borrado con el botón en `variant` por defecto y sin botón de cancelar | [`components/menus/delete-menu-dialog.tsx`](app/javascript/components/menus/delete-menu-dialog.tsx) | `variant="destructive"` y `DialogClose` con «Cancelar» |
| Control segmentado armado con `<button>` a mano | [`components/appearance-tabs.tsx`](app/javascript/components/appearance-tabs.tsx) (plantilla) | `ToggleGroup` |
| Aviso «Saved» con `Transition` de `@headlessui/react` | `pages/settings/profiles/show.tsx`, `passwords/show.tsx`, `emails/show.tsx` (plantilla) | Flash del servidor; al migrar los tres, evaluar quitar `@headlessui/react` |
| `navItems` por rol definidos dos veces | [`components/app-sidebar.tsx`](app/javascript/components/app-sidebar.tsx) y [`components/app-header.tsx`](app/javascript/components/app-header.tsx) | Extraer una única lista compartida |
| Dashboards con `PlaceholderPattern` | [`components/dashboard.tsx`](app/javascript/components/dashboard.tsx) | Reemplazar al construir cada dashboard |

## Checklist para revisiones y agentes de IA

- [ ] Botones, campos, tarjetas, badges, alertas y diálogos usan el componente de la lista.
- [ ] No hay `<button>`, `<input>`, `<select>` ni `<textarea>` estilizados a mano que repliquen un componente de la lista.
- [ ] Los imports salen de `@/components/ui/<componente>` (sin categorías) y no de `radix-ui` ni `@base-ui/react`.
- [ ] No se editó ningún archivo de `components/ui/` a mano.
- [ ] Nada copiado del prototipo conserva `*.module.css`, `styles.*` ni el `Select` nativo.
- [ ] Cada control de formulario está en un `Field`, tiene `name`, `id` coincidente con `FieldLabel` y muestra errores con `FieldError`. Los `Select` tienen `name`.
- [ ] Si se agregó un componente: se hizo con el CLI y figura en este archivo.
- [ ] Si se migró un patrón pendiente, se borró su fila.
- [ ] Los botones con ícono solo tienen `aria-label`; los íconos decorativos, `aria-hidden="true"`.
