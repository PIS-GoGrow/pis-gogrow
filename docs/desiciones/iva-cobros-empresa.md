# IVA en los cobros a GoGrow (IBP-059)

Decisión funcional del 12/10/2026, autorizada para corregir el resumen de cobros del proveedor del PR #93. Pendiente de confirmación con el cliente.

Para las nuevas cuentas de empresa alcanzadas por la activación, se interpreta `account.amount` como el subtotal sin IVA correspondiente al subsidio. Se agrega el 22 % exclusivamente a esa parte. La referencia es el diseño de Figma (subtotal $16.200, IVA $3.564 y total $19.764) y el comportamiento original del PR #93. Estos antecedentes no confirman si el precio comercial de las viandas incluye IVA; la interpretación tributaria sigue pendiente de validación con GoGrow.

La migración agrega `accounts.vat_rate` como decimal con valor predeterminado cero y sin nulos. Todas las cuentas existentes conservan tasa cero, independientemente de su estado y período, incluidas las cuentas futuras ya creadas. La migración no lee la configuración de activación, no recalcula `amount` ni modifica facturas o pagos. El código anterior que siga creando cuentas después de la migración también obtiene tasa cero por el valor predeterminado de la base.

La activación ocurre cuando el nuevo despliegue ejecuta la aplicación con `COMPANY_ACCOUNT_VAT_ENABLED=true`. `config/deploy.yml` configura esa variable para la nueva versión; fuera del despliegue, la ausencia de la variable o cualquier valor distinto de `true` mantiene desactivada la asignación de IVA. `.env.example` la deja en `false` para desarrollo y pruebas manuales. Ejecutar `db:migrate` por adelantado no activa la funcionalidad.

Al crear una cuenta, Rails asigna y persiste tasa `0.22` únicamente si es de empresa, la activación está habilitada y el período normalizado es octubre de 2026 o posterior. Las cuentas nuevas de períodos anteriores a octubre de 2026 y las cuentas de empleados reciben tasa cero. La tasa es de solo lectura una vez creada la cuenta: no se vuelve a decidir al consultar, agregar pedidos, registrar pagos o cambiar la configuración. Reutilizar una cuenta existente conserva su tasa.

En el despliegue se debe completar el cambio de versión de los procesos que crean cuentas, incluidos los trabajos en segundo plano. Un proceso de la versión anterior conserva el comportamiento anterior y no puede asignar el nuevo impuesto. Si se revierte la aplicación o se deshabilita la activación, las cuentas que ya tienen tasa `0.22` mantienen su tasa; no se deben eliminar la columna ni sus datos como parte de un rollback operativo.

Rails calcula el IVA con `BigDecimal`, redondea por cuenta a dos decimales con mitades hacia arriba y obtiene el total sumando el subtotal y el IVA redondeado. Por ejemplo, un subtotal de $800 produce IVA de $176 y un total de $976.

El subtotal persistido no cambia al consultar, facturar o aprobar pagos. Los resúmenes suman los totales de las cuentas, con el IVA aplicado una sola vez. Los importes esperados de pago y factura usan ese mismo total. Las facturas ya cargadas conservan su importe informado; no se recalculan ni se modifican sus archivos.

Las cuentas de empleados mantienen sus importes y cálculos actuales, sin IVA adicional. El importe de cada vianda y el subsidio de cada pedido siguen siendo los valores originales; el impuesto se calcula sobre el subtotal de la cuenta de empresa. Los cobros históricos y sus saldos usan tasa cero. El tratamiento existente de pagos parciales no cambia.

El detalle mensual de ventas conserva los precios originales de las viandas y agrega un desglose por cliente que suma las cuentas de empresa y empleados. En ese desglose, el IVA se identifica como «IVA sobre subsidios (22 %)»: se calcula solo sobre las cuentas de empresa, no sobre la suma de todas las viandas. El total coincide con el resumen de ventas y el filtro de cliente conserva esa regla.

En ClickUp, IBP-059 corresponde a «Consultar un resumen de cobros y estados de pago» (86e3bjhxx) y su ajuste de pantallas (86e3jeq5q). Las notificaciones de cancelación corresponden a IBP-025 e IBP-072.

## Archivos de la corrección

| Archivos | Motivo |
|---|---|
| `app/models/account.rb` | Centralizar IVA y total con decimales, sin modificar el subtotal persistido. |
| `db/migrate/20261012120000_add_vat_rate_to_accounts.rb`, `db/schema.rb` | Persistir la tasa por cuenta con valor predeterminado cero, preservando las cuentas existentes. |
| `config/deploy.yml`, `.env.example` | Separar la activación del despliegue de la ejecución de la migración. |
| `spec/migrations/add_vat_rate_to_accounts_spec.rb` | Comprobar que la migración conserva los importes y que las inserciones del código anterior siguen recibiendo tasa cero. |
| `app/services/provider_collection_summary.rb` | Sumar los totales con IVA de empresa y los importes originales de empleados; incluir el desglose mensual por cliente. |
| `app/controllers/admin/payments_controller.rb` | Usar el mismo total en deuda, resumen mensual y detalle de pagos de GoGrow. |
| `app/serializers/account_serializer.rb`, `app/serializers/provider/collection_account_serializer.rb`, `app/serializers/provider/collections_index_serializer.rb`, `app/serializers/admin/invoice_serializer.rb` | Exponer los importes calculados por Rails y comparar la factura con el total esperado con IVA. |
| `app/javascript/components/collections/collection-account-detail-dialog.tsx`, `collection-account-panel.tsx`, `collection-group-card.tsx`, `invoice-section.tsx`, `sales-detail-dialog.tsx` | Mostrar el desglose y usar el total de Rails para cobros, revisión de comprobantes y monto sugerido de factura. Todos los nombres abreviados pertenecen a este mismo directorio. |
| `app/javascript/pages/provider/collections/show.tsx`, `app/javascript/components/admin/payments/period-card.tsx` | Mantener el total y el desglose en el detalle del proveedor y las tarjetas de pagos de RR. HH. |
| `config/locales/es.yml`, `app/javascript/locales/es.json` | Incorporar las etiquetas en español y exportarlas desde Rails. |
| `app/javascript/types/serializers/Account.ts`, `ProviderCollectionAccount.ts`, `ProviderCollectionsIndex.ts` | Regenerar los contratos TypeScript. Los nombres abreviados pertenecen al mismo directorio; no se editaron los tipos a mano. |
| `spec/models/account_spec.rb`, `spec/services/provider_collection_summary_spec.rb` | Cubrir el cálculo, los ejemplos de Figma, el redondeo por cuenta, los empleados y la prevención de acumulación del IVA. |
| `spec/requests/provider/collections_spec.rb`, `spec/requests/provider/invoices_spec.rb`, `spec/requests/admin/payments_spec.rb`, `spec/requests/admin/invoices_spec.rb` | Verificar los importes entre pantallas, pagos y facturas; conservar el monto informado de las facturas existentes. |
| `app/javascript/components/collections/collection-account-detail-dialog.test.tsx`, `collection-account-panel.test.tsx`, `sales-detail-dialog.test.tsx` | Verificar el desglose, el importe esperado de revisión, el monto sugerido de factura y el filtro por cliente. Los nombres abreviados pertenecen al mismo directorio. |
| `app/javascript/components/consumer/accounts/account-card.test.tsx`, `payment-history-card.test.tsx` | Actualizar los datos de prueba al contrato generado, conservando los importes de empleados. Los nombres abreviados pertenecen al mismo directorio. |
| `docs/desiciones/iva-cobros-empresa.md` | Registrar la interpretación autorizada, sus límites y los archivos que la implementan. |
