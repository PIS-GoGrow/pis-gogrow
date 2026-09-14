import Dashboard from "@/components/dashboard"
import { providerDashboard as dashboard } from "@/routes"

export default function ProveedorDashboard() {
  return <Dashboard url={dashboard.index().url} role_name="Proveedor" />
}
