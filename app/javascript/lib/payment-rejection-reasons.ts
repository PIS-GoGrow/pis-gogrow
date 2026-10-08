// Motivo de rechazo que el proveedor elige cuando el comprobante enviado
// corresponde solo a una parte de la deuda. rejection_reason es un campo de
// texto libre (no un enum), así que se compara literalmente contra este
// motivo estándar para decidir si mostrarle al cliente el aviso de pago
// parcial en lugar del mensaje de rechazo genérico.
export const PARTIAL_PAYMENT_REJECTION_REASON = "El pago es parcial"
