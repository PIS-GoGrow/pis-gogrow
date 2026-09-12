import Dashboard from "@/components/dashboard"
import { consumerDashboard as dashboard } from "@/routes"

export default function ConsumerDashboard() {
  return (
  	<Dashboard url={dashboard.index().url} role_name="Consumer" />
  )
}	

