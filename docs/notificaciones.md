# Vista general

# Checklist para agregar notificaciones a un flujo:

## 0. Decisiones:
Es necesario decidir para el tipo de notificación que queremos agregar:
- quién la va a recibir (qué usuario)
- con cuál de sus roles (consumer, admin, provider)
- si requiere acción. Si requiere acción, el usuario no la puede cerrar, sino que
  necesita hacer algo para que se cierre. En el Figma, estas notificaciones
  aparecen en rojo.
- qué objeto la originó. [Más adelante](#notifiable) se explica mejor esto.

## 1. Revisar que exista la configuración:
Todas las notificaciones deben tener un
Notification::Configuration asociado, por lo que es necesario que ya exista
la configuración que vamos a asociar a este flujo. [Ver más sobre las configuraciones](#configuraciones).
Luego de esto, deberíamos obtener una clave de configuración.

## 2. Registrar el evento:
Las notificaciones están separados según el flujo o «evento» que los genera. Es necesario
registrar el evento que estamos implementando. [Ver más sobre esto](#eventos).

## 4. Crear los locales:
Es necesario agregar título y descripción de la notificación a
`config/locales/es.yml`. Si creamos una clave de evento `event_key` en el paso 2,
tenemos que agregar al archivo:
```
notifications:
  event_key:
    title: "..."
    description: "..."
```

si la notificación requiere datos extra del momento, los agregamos con `%{dato}`
adentro del string y los pasamos al momento de crear la notificación.

## 5. Crearla en el flujo:
En el punto del flujo que sea necesario notificar a un usuario, se crea una
notificación llamando al servicio Notifier. Nunca habría que llamar a
Notification.create directamente. [Más información](#notifier)

## 6. Definir cómo cerrarlas:
Si la notificación no requiere acción, este paso no es necesario. Hay que definir
en qué punto una notificación puede ser cerrada. Cuando la condición se cumpla para
que al usuario ya no le aparezca la notificación, hay que llamar a `Notification.close_by!`
o `Notification.close_by`. Es necesario indicar la clave de evento, el objeto
`notifiable` y el usuario que se eligieron en el paso 3.

Las notificaciones que requieren acción no se van nunca si no hacemos esto, por
lo que hay que estar seguro de que eventualmente se va a llamar a `close_by` de
alguna forma, y que no hay manera de evitarlo si es que se realiza la acción
requerida.

# Configuraciones

Cada tipo de notificación debe pertenecer a una configuración, por lo que para poder
crear una notificación, es necesario saber a qué configuración va a pertenecer.
Las configuraciones se guardan en la base de datos en `Notification::Configuration`.
Las configuraciones en principio son las que aparecen en la pantalla de configurar
notificaciones en el Figma para cada rol. Además, hay que saber desde qué roles
se puede acceder a una configuración.

Un ejemplo de configuración podría ser «Actualización de pedido» con clave
`order_updates`, para que el usuario pueda configurar si recibe notificaciones cuando
se modifica uno de sus pedidos. Además, dentro de esa configuración podría encontrarse
el evento «Confirmación de pedido» y «Cancelación de pedido». El usuario configura
ambos a la vez como «Actualización de pedido», pero en realidad son tipos separados.
Esta configuración solo aplica a consumidores, por lo que tiene `roles = [consumer]`.

No manejamos directamente las configuraciones, sino que las definimos en
`config/notifications.yml`, y luego de ejecutar el comando `bin/rails notifications:sync`
se pasan automáticamente para estar disponibles en la aplicación. Necesitamos definir
de una configuración su clave y a qué roles aplica.

El título y la descripción de una configuración no se define ahí,
sino que se configura desde los locales, según la clave. Si creamos una
`Notification::Configuration` con clave `:order_updates`, es necesario entonces tener
en `es.yml` las líneas:
```
notification_configurations:
  order_updates:
    title: "..."
    description: "..."
```
Cuando un usuario quiere recibir tipos de notificaciones asociadas a una determinada
configuración, se asocia a la configuración. Si el usuario no tiene un rol presente
en el atributo roles de la configuración, no puede asociarse.

La configuración solo se toma en cuenta cuando la notificación se envía
por WhatsApp, todas las notificaciones aparecen siempre en la app. Las
configuraciones tienen una clave (`key`) que las identifica y además indican qué roles
(`consumer`, `provider`, `admin`) pueden configurarlas.

# Eventos
Cada flujo genera notificaciones con un determinado evento asociado. Los eventos
se identifican con una clave, que se guarda en el modelo `Notification`. Un evento
podría ser «Confirmación de pedido».

Cada evento pertenece a una única configuración para que el usuario pueda administrar
las notificaciones en grupo.

## Registro de eventos
Si queremos registrar un evento, en `config/notifications.yml` hay que agregar en
`events` la información de nuestro flujo:

1. Agregar bajo `events` una clave única para nuestro flujo. Por ejemplo, para
el flujo «Notificar confirmación de pedidos» podría ser `order_confirmation`.

2. Agregar una clave de configuración.

3. Especificar el rol (`consumer`, `admin`, `provider`)

4. Especificar si la notificación requiere acción.

# Notifier
`Notifier` es el servicio encargado de crear notificaciones. Una vez creada una
notificación mediante `Notifier`, no hay que preocuparse por cómo se le muestra al
usuario o si se envía, esto se hace automáticamente.

Para crearla, es necesario pasarle:
- qué evento originó la notificación (`event_key`);
- a qué usuario enviarle la notificación (`user`);
- a qué rol del usuario mostrarle la notificación (`role`, que puede ser `consumer`,
  `admin` o `provider`);
- qué objeto ocasionó la notificación ([`notifiable`](#notifiable)).

## Notifiable
El objeto `notifiable` conceptualmente debería representar el objeto responsable de que
se le esté enviando una notificación al usuario. Además, si la notificación requiere
acción, entonces la acción tendría que hacerse sobre el objeto `notifiable`.
Por ejemplo:
- Si el evento es que se confirmó un pedido, `notifiable` es ese pedido
- Si el evento es que hay pagos pendientes, `notifiable` es la cuenta en la que hay un
  pago pendiente.

Para tener en cuenta, para un mismo evento, usuario y `notifiable`, puede haber una
única notificación. Entonces, un `notifiable` no debe poder generar varias
notificaciones a un mismo usuario en el mismo evento.

Si los locales definidos para una notificación necesitan datos extra, se pueden pasar
en `title_data` y `description_data`.
