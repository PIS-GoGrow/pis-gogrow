import Dashboard from "@/components/dashboard"
import { adminDashboard as dashboard } from "@/routes"

export default function AdminDashboard() {
  return (
  	<Dashboard url={dashboard.index().url} role_name="Administrador" />
  )
}	

