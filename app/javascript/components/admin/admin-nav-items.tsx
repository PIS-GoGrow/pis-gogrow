import {
  CreditCardPosIcon,
  Home09Icon,
  UserGroupIcon,
  UserIcon,
} from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { CreditCard, House, UserRound, UsersRound } from "lucide-react"
import type { ReactElement } from "react"
import { useTranslation } from "react-i18next"

import {
  adminBenefitConfigurations,
  adminConsumers,
  adminDashboard,
  adminPayments,
  settingsProfiles,
} from "@/routes"
import type { NavItem } from "@/types"

type AdminPrimaryNavItem = NavItem & {
  mobileIcon: ReactElement
  mobileActivePaths?: string[]
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
          icon={Home09Icon}
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
      href: adminPayments.index().url,
      icon: CreditCard,
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
      mobileActivePaths: ["/settings", adminBenefitConfigurations.index().url],
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
