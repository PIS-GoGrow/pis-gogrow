import {
  CreditCardPosIcon,
  Home01Icon,
  UserGroupIcon,
  UserIcon,
} from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { CreditCard, House, UserRound, UsersRound } from "lucide-react"
import type { ReactElement } from "react"
import { useTranslation } from "react-i18next"

import { adminConsumers, adminDashboard, settingsProfiles } from "@/routes"
import type { NavItem } from "@/types"

type AdminPrimaryNavItem = NavItem & {
  mobileIcon: ReactElement
  mobileActivePrefix?: string
}

export function useAdminPrimaryNavItems(): AdminPrimaryNavItem[] {
  const { t } = useTranslation()

  return [
    {
      title: t("nav.admin.home"),
      href: adminDashboard.index().url,
      icon: House,
      mobileIcon: (
        <HugeiconsIcon
          icon={Home01Icon}
          className="size-6"
          strokeWidth={2}
          aria-hidden="true"
        />
      ),
    },
    {
      title: t("nav.admin.employees"),
      href: adminConsumers.index().url,
      icon: UsersRound,
      mobileIcon: (
        <HugeiconsIcon
          icon={UserGroupIcon}
          className="size-6"
          strokeWidth={2}
          aria-hidden="true"
        />
      ),
    },
    {
      title: t("nav.admin.payments"),
      href: adminDashboard.index().url,
      icon: CreditCard,
      disabled: true,
      mobileIcon: (
        <HugeiconsIcon
          icon={CreditCardPosIcon}
          className="size-6"
          strokeWidth={2}
          aria-hidden="true"
        />
      ),
    },
    {
      title: t("nav.admin.account"),
      href: settingsProfiles.show().url,
      icon: UserRound,
      mobileActivePrefix: "/settings",
      mobileIcon: (
        <HugeiconsIcon
          icon={UserIcon}
          className="size-6"
          strokeWidth={2}
          aria-hidden="true"
        />
      ),
    },
  ]
}
