import { createContext, useContext, useState } from "react"
import type { Dispatch, ReactNode, SetStateAction } from "react"

interface MenuFilterState {
  activeProviders: Set<number>
  setActiveProviders: Dispatch<SetStateAction<Set<number>>>
}

const MenuFilterContext = createContext<MenuFilterState | null>(null)

export function ConsumerMenuFilterProvider({
  children,
}: {
  children: ReactNode
}) {
  const [activeProviders, setActiveProviders] = useState<Set<number>>(new Set())

  return (
    <MenuFilterContext value={{ activeProviders, setActiveProviders }}>
      {children}
    </MenuFilterContext>
  )
}

export function useConsumerMenuFilter() {
  const state = useContext(MenuFilterContext)
  if (!state) throw new Error("ConsumerMenuFilterProvider is required")
  return state
}
