import "./application.css"
import "../lib/i18next"

import { createRoot } from "react-dom/client"

import OfflineApp from "@/pages/offline/index"

createRoot(document.getElementById("root")!).render(<OfflineApp />)
