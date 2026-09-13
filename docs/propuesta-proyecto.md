# Propuesta de proyecto: GoGrow

> Propuesta presentada por GoGrow para el curso Proyecto de Ingeniería de Software 2026 (GrIS, InCo – Facultad de Ingeniería, UdelaR).
>
> Transcripción de «Propuesta Proyecto 2026 GoGrow.pdf». Cambios respecto al PDF: se omiten el teléfono y el correo de contacto, y se corrigen erratas en los nombres de las tecnologías («Interia.js», «Intertia.js»).

## 1. Proponente

- **Institución:** GoGrow
- **Dirección:** 18 de Julio 1006, Apto 401, Montevideo

### 1.1 Persona de contacto

Franco Pariani, CEO.

### 1.2 Personas que van a definir requerimientos

- Bruno Pariani, Director Creativo
- Fiorella Prinzo, Recursos Humanos y Operaciones
- Franco Pariani, CEO

## 2. Descripción del proyecto

### 2.1 Contexto y dominio de aplicación

GoGrow subsidia el 50 % del costo de las viandas de cada empleado, trabajando con dos proveedores de comida (TuViandita y Endulzate by Noe). Después de cada mes, se comparte un archivo Google Sheets con el detalle del consumo de cada empleado y el monto total adeudado. Luego, los empleados deben transferir su gasto correspondiente tanto a la cuenta bancaria de GoGrow como a la de los proveedores.

Aunque este beneficio ha sido muy exitoso y aplaudido por el equipo, el sistema posee ineficiencias. Existen demoras significativas en la conciliación de consumos, lo que provoca pérdidas económicas cuando empleados que ya no están en la empresa no reembolsan sus viandas. Además, el proceso actual genera una alta carga manual y cognitiva tanto para empleados como para el equipo de RR.HH., incrementando el riesgo de errores, pagos omitidos y disputas.

A su vez, el uso de hojas compartidas expone información sensible sobre quién pagó o no. Todo esto implica un uso ineficiente del tiempo administrativo, que podría destinarse a tareas de mayor valor estratégico.

### 2.2 Objetivos

El primer objetivo del proyecto es **reducir la carga administrativa y operativa** asociada a la gestión de viandas. A través de la automatización de procesos como la conciliación de consumos, el seguimiento de pagos y la generación de reportes, se busca disminuir significativamente el tiempo que RR.HH. y administración destinan a tareas manuales, permitiéndoles enfocarse en actividades de mayor valor estratégico.

El segundo objetivo consiste en **optimizar el ciclo de pagos y mejorar la disciplina financiera** dentro del beneficio. La plataforma deberá facilitar el seguimiento en tiempo real del consumo y del estado de pagos, promoviendo que la gran mayoría de los empleados regularice sus consumos dentro del ciclo mensual y evitando retrasos que generen pérdidas económicas o desbalances de caja para la empresa.

El tercer objetivo es **mejorar la experiencia y satisfacción de los empleados** mediante una herramienta clara, simple y transparente. Al brindar visibilidad individual sobre consumos, subsidios y montos adeudados, junto con recordatorios automáticos y procesos más ágiles, se busca reducir fricciones, confusiones y situaciones incómodas relacionadas con pagos atrasados o información pública sensible.

El cuarto objetivo apunta a **aumentar la previsibilidad financiera y la capacidad de planificación** de la empresa. Mediante datos centralizados y reportes actualizados en tiempo real, GoGrow podrá proyectar con mayor precisión los gastos asociados al beneficio de viandas, controlar variaciones y tomar decisiones basadas en información confiable.

Finalmente, el proyecto busca **reducir errores, disputas y riesgos operativos** derivados de procesos manuales y descentralizados. La digitalización y automatización de registros permitirá minimizar inconsistencias, evitar pérdidas económicas por omisiones o errores humanos y generar un sistema escalable que acompañe el crecimiento de la organización sin aumentar proporcionalmente la carga administrativa.

### 2.3 Descripción de las principales características del producto a construir

**Autenticación y perfiles de usuario:** acceso mediante login móvil (por ejemplo, OTP por SMS o WhatsApp) con roles diferenciados (empleado, RR.HH./Admin y proveedor). Permite gestionar permisos y asegurar que cada usuario vea únicamente la información relevante para su rol.

**Gestión de menús y pedidos:** publicación de menús diarios o semanales por parte de los proveedores. Los empleados podrán visualizar opciones, seleccionar comidas para fechas específicas y omitir días cuando no deseen consumir viandas.

**Gestión automática de subsidios:** configuración de reglas de subsidio (porcentaje, días aplicables u otras condiciones) que se aplican automáticamente al momento del pedido, evitando cálculos manuales y errores administrativos.

**Sistema de cuponeras (vouchers de comidas):** compra y gestión de paquetes de comidas (por ejemplo, 5, 10 o 20 viandas), con descuento automático del saldo disponible y posibilidad de arrastrar consumos no utilizados.

**Seguimiento de consumo y reportes:** visualización del gasto y consumo semanal o mensual para empleados, mientras que RR.HH. podrá acceder a reportes consolidados por persona, proveedor y consumo total.

**Portal administrativo y gestión de proveedores:** herramientas para que RR.HH. configure proveedores, reglas de subsidio y ventanas de pedidos. Los proveedores podrán publicar menús, administrar platos y visualizar órdenes recibidas.

**Notificaciones y recordatorios automáticos:** alertas generadas por el sistema para fechas límite de pedidos, recordatorios de pago o vencimientos, reduciendo retrasos y olvidos.

**Visibilidad en tiempo real del estado de pagos y consumos:** paneles actualizados automáticamente que muestran balances, consumos y estado de pagos de forma privada para cada usuario, promoviendo transparencia sin exponer información sensible.

**Sistema de ratings y reviews (opcional):** los empleados podrán calificar las viandas y dejar comentarios sobre calidad, sabor, porciones o puntualidad del servicio. Esto permitirá a RR.HH. y a los proveedores obtener feedback directo y continuo para mejorar la oferta gastronómica, detectar problemas recurrentes y tomar decisiones basadas en la experiencia real de los usuarios.

**Sistema de pasarela de pagos integrada (opcional):** integración con una pasarela de pagos para permitir que los empleados abonen sus consumos de forma digital, rápida y segura directamente desde la aplicación. La funcionalidad permitirá registrar pagos automáticamente, reducir transferencias manuales y simplificar la conciliación financiera, mejorando la trazabilidad y disminuyendo errores administrativos.

### 2.4 Resultados esperados

Una aplicación web funcional (MVP) que permita gestionar de punta a punta el beneficio de viandas: pedidos, aplicación automática de subsidios, seguimiento de consumos y conciliación de pagos, con portal administrativo para RR.HH. y proveedores, sistema de notificaciones y paneles de reportes en tiempo real.

Se espera una reducción significativa del tiempo administrativo dedicado a la gestión de viandas, una disminución de errores y pérdidas económicas por pagos atrasados o conciliaciones tardías, y una mejora en la previsibilidad financiera de GoGrow.

### 2.5 Uso previsto de los resultados

La aplicación será puesta en uso interno por GoGrow para reemplazar el proceso manual actual (planilla de Google Sheets y transferencias bancarias), siendo utilizada de forma continua por empleados, RR.HH./Administración y los proveedores de comida (TuViandita y Endulzate by Noe) para la gestión mensual del beneficio de viandas.

### 2.6 Lenguaje y herramientas de implementación

Aplicación web implementada con Ruby on Rails (se sugiere incorporar React con Inertia.js), shadcn/ui para los componentes de interfaz, PostgreSQL como base de datos, y despliegue sobre infraestructura propia en AWS.

### 2.7 Requerimientos especiales de equipamiento para el desarrollo o prueba

No se requiere equipamiento especial de procesamiento.

### 2.8 Requerimientos especiales de software para el desarrollo o prueba

Cuentas de despliegue en AWS y accesos de prueba a los servicios de OTP (SMS/WhatsApp) y, en caso de implementarse la funcionalidad opcional de pagos, a una pasarela de pagos; estos accesos serán provistos por GoGrow.

### 2.9 Restricciones tecnológicas

El stack tecnológico está definido por: Inertia.js (frontend), Ruby on Rails (backend), shadcn/ui (componentes de interfaz) y PostgreSQL (base de datos), con despliegue en AWS.

#### 2.9.1 Interfaces con componentes o servicios externos

Servicio de autenticación mediante OTP vía SMS o WhatsApp. De implementarse la funcionalidad opcional correspondiente, integración con una pasarela de pagos para que los empleados abonen sus consumos de forma digital, con registro automático de pagos.

Las secciones 2.9.2 (otras restricciones y dependencias), 2.9.3 (conocimientos específicos requeridos), 2.9.4 (capacitación ofrecida) y 2.10 (otra información relevante) quedaron sin completar en la propuesta.
