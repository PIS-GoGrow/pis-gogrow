# Checklist para agregar notificaciones a un flujo:

0. Decidir para la notificación:
   - quién la va a recibir (qué usuario)
   - con qué rol (consumer, admin, provider)
   - si requiere acción. Si requiere acción, el usuario no la puede cerrar, sino que
     necesita hacer algo para que se cierre. En el Figma, estas notificaciones
     aparecen en rojo.
   - qué objeto la originó. Más adelante se explica mejor esto.
1. Revisar que exista la configuración: Todas las notificaciones deben tener un
   Notification::Configuration asociado, por lo que es necesario que ya exista
   la configuración que vamos a asociar a este flujo. Revisar el archivo
>     app/models/notification/configuration.rb
   para ver más. Luego de esto, deberíamos obtener una clave de configuración.
2. Registrar el evento: Los tipos de notificaciones están separados según el
   flujo o "evento" que los genera. En config/notifications.yml hay que agregar
   en events la información de nuestro flujo:
   2.1. Agregar bajo events una clave única para nuestro flujo. Por ejemplo, para
        el flujo «Notificar confirmación de pedidos» podría ser order_confirmation.
   2.2. Agregar la clave de configuración encontrada en el paso 1 bajo la clave del
        paso 2.1.
   2.3. Especificar el rol (consumer, admin, provider)
   2.4. Especificar si la notificación requiere acción.
   Los detalles del formato están en config/notifications.yml.
3. Crear los locales: Es necesario agregar título y descripción de la notificación a
   config/locales/es.yml. Si creamos una clave de evento 'event_key' en el paso 2,
   tenemos que agregar al archivo:
```      notifications:
        event_key:
          title: "..."
          description: "..."
          ```

   si la notificación requiere datos extra del momento, los agregamos con %{dato}
   adentro del string.
4. Crearla en el flujo: En el punto del flujo que sea necesario notificar a un
   usuario, se crea una notificación llamando al servicio Notifier. Nunca habría
   que llamar a Notification.create directamente.
   Hay más información en app/services/notifier.rb de cómo crearlas.
5. Definir cómo cerrarlas: Si la notificación no requiere acción, este paso no es
   necesario. Hay que definir en qué punto una notificación puede ser cerrada.
   Cuando la condición se cumpla para que al usuario ya no le aparezca la
   notificación, hay que llamar a Notification.close_by! o Notification.close_by.
   Es necesario indicar la clave de evento, el objeto notifiable y el usuario
   que se eligieron en el paso 3.
   Las notificaciones que requieren acción no se van nunca si no hacemos esto, por
   lo que hay que estar seguro de que eventualmente se va a llamar a close_by de
   alguna forma, y que no hay manera de evitarlo si es que se realiza la acción
   requerida.