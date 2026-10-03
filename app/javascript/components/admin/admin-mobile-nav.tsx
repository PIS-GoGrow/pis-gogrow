import { usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { useAdminPrimaryNavItems } from "@/components/admin/admin-nav-items"
import MobileNav from "@/components/mobile-nav"

export function AdminMobileNav() {
  const { t } = useTranslation()
  const { url } = usePage()
  const navItems = useAdminPrimaryNavItems()
  const pathname = url.split("?")[0]

  return (
    <MobileNav
      className="bottom-6"
      label={t("nav.admin.mobile_navigation")}
      pendingTitle={t("pages.admin.dashboard.coming_soon")}
      items={navItems.map((item) => ({
        label: item.title,
        icon: item.mobileIcon,
        href: item.disabled ? undefined : item.href,
        active:
          !item.disabled &&
          (item.mobileActivePaths ?? [item.href]).some(
            (path) => pathname === path || pathname.startsWith(`${path}/`),
          ),
      }))}
    />
  )
}
