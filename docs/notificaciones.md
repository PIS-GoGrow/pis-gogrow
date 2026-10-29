# Vista general
En la aplicación, los modelos `Notification::Configuration` y `Notification`
son los que se encargan de manejar [configuraciones de notificación](#configuracion)
y el almacenamiento de notificaciones.

El servicio [`Notifier`](#notifier) se encarga de crearlas.

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

**Nota:** Si hubiera un evento que no tenga aparentemente ninguna configuración
asociada en el Figma, habría que crear una configuración para ese evento y asignarle
el atributo `configurable: false`. En ese caso, el usuario no tendría manera de
desactivar esa configuración.

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
- qué objeto ocasionó la notificación ([`notifiable`](#notifiable)).

El resto de cosas necesarias para crear la notificación se infieren a partir de lo
configurado para el evento

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

# WhatsappSenderJob
Envía un mensaje de WhatsApp para una notificación.

Para que funcione, necesitan estar cargadas las credenciales. En development,
solo corre cuando esta configurada la variable `TWILIO_DELIVERY_ENABLED=true`.
Las credenciales se configuran con `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`,
`TWILIO_PHONE`.

Mientras está corriendo el job, su notificación se marca con estado `sending`.
Cuando hay un error de red, Twilio responde 429 o un 5xx, se reintenta hasta cinco
veces el envío. Si los cinco intentos fallan, se marca la notificación con el
estado `send_failed`. Cualquier otro error de Twilio (un 4xx: credenciales, número o
variables inválidas) no se reintenta y marca `send_failed` en el momento. Si el Job fue
exitoso, marca la notifiación con estado `accepted` y registra la hora de envío en el
atributo `whatsapp_sent_at`.

`whatsapp_sent_at` y `accepted` solo dicen si Twilio aceptó el mensaje, no si llegó
al celular. Los errores de entrega (por ejemplo, que el número no tenga WhatsApp)
Twilio los informa después, por el status callback. Para poder recibir los callbacks
de Twilio en ambiente de dev, es necesario configurar la variable
`TWILIO_STATUS_CALLBACK_URL` a la URL pública que se esté usando (por ejemplo con
un túnel de cloudflare) más `/twilio-callback`.

Una vez que llega el callback de Twilio, la notificación se marca como `delivered`
si el envío fue exitoso. Si no, se marca como `delivery_failed` y se reintenta hasta
un máximo de 5 veces (en los reintentos, la notificación va a volver a pasar por los
estados `sending` y `accepted`).

`User` guarda el teléfono en formato internacional (`+59899123456`), que es el que
pide Twilio: lo normaliza con `phonelib`, interpretando como uruguayo un número sin
`+`, y solo acepta celulares.

Los datos extra de locales de notificaciones se pasan a Twilio, agregando `title_`
a las claves de los datos de título y agregando `description_` a las claves de
datos de descripción.

Cada evento tiene una plantilla en Twilio (Content Template Builder) con el mismo
texto que `config/locales/es.yml`: el título en negrita en la primera línea y la
descripción abajo, con cada `%{dato}` reemplazado por `{{description_dato}}`. Las
plantillas se llaman `gogrow_<evento>` y su SID va en `content_sid` de
`config/notifications.yml`. Si la descripción tiene singular y plural, hay una
plantilla para cada forma (`gogrow_<evento>_one` y `gogrow_<evento>_other`) y el Job
elige según el dato `count`. Si se cambia un texto en `es.yml`, hay que crear una
plantilla nueva en Twilio y actualizar su SID: las plantillas no se pueden editar.

Este Job no debería ser accedido desde ningún lugar, menos el servicio `Notifier`.
Supone que Notifier ya chequeó que la clave de evento exista y que todas las
notificaciones tienen un content SID asignado.

Si `Notifier` decide no enviar la notificación, se marca con estado `skipped`.
