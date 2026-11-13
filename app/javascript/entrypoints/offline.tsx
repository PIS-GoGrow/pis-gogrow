import "./application.css"
import "../lib/i18next"
import { createRoot } from "react-dom/client"

import { initializeTheme } from "@/hooks/use-appearance"
import OfflineApp from "@/pages/offline/index"

// This will set light / dark mode on load...
initializeTheme()

createRoot(document.getElementById("root")!).render(<OfflineApp />)
