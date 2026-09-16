import { Link, router } from "@inertiajs/react"
import {
  ChefHat,
  LogOut,
  Settings,
  User as UserIcon,
  UserStar,
} from "lucide-react"
import { useTranslation } from "react-i18next"

import {
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu"
import { UserInfo } from "@/components/user-info"
import { useMobileNavigation } from "@/hooks/use-mobile-navigation"
import { sessions, settingsProfiles } from "@/routes"
import type { User } from "@/types"

interface UserMenuContentProps {
  auth: {
    session: {
      id: number
      role: string
    }
    user: User
  }
}

export function UserMenuContent({ auth }: UserMenuContentProps) {
  const { t } = useTranslation()
  const { session, user } = auth
  const cleanup = useMobileNavigation()

  const handleLogout = () => {
    cleanup()
    router.flushAll()
  }

  const user_icons = {
    consumer: <UserIcon className="mr-2" />,
    provider: <ChefHat className="mr-2" />,
    admin: <UserStar className="mr-2" />,
  }

  const inactive_roles = user.roles.filter((r) => r !== session.role)
  const roles_buttons = inactive_roles.map((r) => (
    <DropdownMenuItem key={r} asChild>
      <Link
        className="block w-full"
        href={sessions.update(session.id)}
        data={{ role: r }}
        as="button"
      >
        {user_icons[r]}
        {t("nav.change_to")} {t("common." + r)}
      </Link>
    </DropdownMenuItem>
  ))

  return (
    <>
      <DropdownMenuLabel className="p-0 font-normal">
        <div className="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
          <UserInfo user={user} showEmail={true} />
        </div>
      </DropdownMenuLabel>
      <DropdownMenuSeparator />
      <DropdownMenuGroup>
        <DropdownMenuItem asChild>
          <Link
            className="block w-full"
            href={settingsProfiles.show()}
            as="button"
            prefetch
            onClick={cleanup}
          >
            <Settings className="mr-2" />
            {t("common.settings")}
          </Link>
        </DropdownMenuItem>
      </DropdownMenuGroup>
      <DropdownMenuSeparator />
      {roles_buttons}
      <DropdownMenuItem asChild>
        <Link
          className="block w-full"
          href={sessions.destroy(session.id)}
          as="button"
          onClick={handleLogout}
        >
          <LogOut className="mr-2" />
          {t("common.log_out")}
        </Link>
      </DropdownMenuItem>
    </>
  )
}
