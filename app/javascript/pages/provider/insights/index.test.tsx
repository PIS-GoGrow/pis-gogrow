import { render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import ProviderInsights from "./index"

const { routerGet } = vi.hoisted(() => ({ routerGet: vi.fn() }))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { get: routerGet },
    Link: ({
      children,
      href,
      ...props
    }: {
      children: React.ReactNode
      href: string | { url: string }
    }) => (
      <a href={typeof href === "string" ? href : href.url} {...props}>
        {children}
      </a>
    ),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const fetchMock = vi.fn<typeof fetch>()
const response = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  })

function deferred() {
  let resolve!: (value: Response) => void
  const promise = new Promise<Response>((done) => {
    resolve = done
  })
  return { promise, resolve }
}

beforeEach(() => {
  routerGet.mockClear()
  fetchMock.mockReset()
  vi.stubGlobal("fetch", fetchMock)
  const meta = document.createElement("meta")
  meta.name = "csrf-token"
  meta.content = "test-csrf-token"
  document.head.appendChild(meta)
})
afterEach(() => {
  vi.unstubAllGlobals()
  document.querySelector('meta[name="csrf-token"]')?.remove()
})

describe("Provider Insights Page", () => {
  const defaultProps = {
    from: "2026-10-01",
    to: "2026-10-31",
    default_from: "2026-10-01",
    default_to: "2026-10-31",
    min: "2026-06-15",
    max: "2026-10-31",
    month_label: "Octubre 2026",
    presets: [
      { key: "today" as const, from: "2026-10-25", to: "2026-10-25" },
      { key: "yesterday" as const, from: "2026-10-24", to: "2026-10-24" },
      { key: "this_week" as const, from: "2026-10-25", to: "2026-10-25" },
      { key: "this_month" as const, from: "2026-10-01", to: "2026-10-31" },
      { key: "last_month" as const, from: "2026-09-01", to: "2026-09-30" },
    ],
    orders_count: 84,
    dishes_count: 15,
    average_rating: 4.7,
    top_dishes: [
      { id: 1, name: "Milanesa con Puré", orders_count: 24 },
      { id: 2, name: "Wok de Verduras", orders_count: 18 },
    ],
    top_rated_dishes: [
      { id: 2, name: "Wok de Verduras", rating: 5 },
      { id: 3, name: "Lasaña veggie", rating: 4.9 },
    ],
  }

  const conclusion = (from = defaultProps.from, to = defaultProps.to) => ({
    success: true,
    text: "La milanesa recibe buenas valoraciones.\n\nAlgunas reseñas mencionan demoras.",
    period: { from, to },
    review_count: 6,
    generated_by_ai: true,
    comments: ["comentario individual privado"],
  })

  it("muestra el título, el volver al Inicio y el período elegido", () => {
    render(<ProviderInsights {...defaultProps} />)

    expect(
      screen.getByRole("heading", { name: "Hallazgos" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver al inicio" }),
    ).toHaveAttribute("href", "/proveedor/inicio")
    expect(screen.getByRole("button", { name: "Período" })).toHaveTextContent(
      "Octubre 2026",
    )
  })

  it("muestra métricas y una tarjeta inicial sin conclusiones ni leyenda de IA", () => {
    render(<ProviderInsights {...defaultProps} />)

    expect(screen.getByText("84")).toBeInTheDocument()
    expect(screen.getByText("Pedidos")).toBeInTheDocument()
    expect(screen.getByText("15")).toBeInTheDocument()
    expect(screen.getByText("Platos")).toBeInTheDocument()
    expect(screen.getByText("4.7")).toBeInTheDocument()
    expect(screen.getByText("Valoración")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Las conclusiones de las reseñas estarán disponibles cuando las generes.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    ).toBeEnabled()
    expect(screen.queryByText("Generado por IA")).not.toBeInTheDocument()
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it("lista los platos más pedidos y los mejor valorados", () => {
    render(<ProviderInsights {...defaultProps} />)

    const topDishes = screen.getByRole("region", {
      name: "Platos más pedidos",
    })
    const rows = within(topDishes).getAllByRole("listitem")
    expect(rows.map((row) => row.textContent)).toEqual([
      "Milanesa con Puréx24",
      "Wok de Verdurasx18",
    ])

    const topRated = screen.getByRole("region", { name: "Mejor valorados" })
    expect(
      within(topRated)
        .getAllByRole("listitem")
        .map((row) => row.textContent),
    ).toEqual(["Wok de Verduras5", "Lasaña veggie4.9"])
  })

  it("muestra ceros, un guión y los estados vacíos sin actividad", () => {
    render(
      <ProviderInsights
        {...defaultProps}
        orders_count={0}
        dishes_count={0}
        average_rating={undefined}
        top_dishes={[]}
        top_rated_dishes={[]}
      />,
    )

    expect(screen.getAllByText("0")).toHaveLength(2)
    expect(screen.getByText("—")).toBeInTheDocument()
    expect(
      screen.getByText("Todavía no hay pedidos en este período"),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Todavía no hay reseñas en este período"),
    ).toBeInTheDocument()
    expect(screen.queryByRole("listitem")).not.toBeInTheDocument()
  })

  it("muestra un rango custom con el formato de rango", () => {
    render(
      <ProviderInsights
        {...defaultProps}
        from="2026-08-02"
        to="2026-09-04"
        month_label={undefined}
      />,
    )

    expect(screen.getByRole("button", { name: "Período" })).toHaveTextContent(
      "02/08/26 – 04/09/26",
    )
  })

  it("ofrece los presets en orden y navega al rango del preset", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    const presets = ["Hoy", "Ayer", "Esta semana", "Este mes", "Mes pasado"]
    for (const label of presets) {
      expect(screen.getByRole("button", { name: label })).toBeInTheDocument()
    }
    await user.click(screen.getByRole("button", { name: "Mes pasado" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-09-01&hasta=2026-09-30",
      {},
      { preserveScroll: true, onFinish: expect.any(Function) as () => void },
    )
    expect(
      screen.queryByRole("button", { name: "Hoy" }),
    ).not.toBeInTheDocument()
  })

  it("vuelve a la ruta sin parámetros con el rango por defecto", async () => {
    const user = userEvent.setup()
    render(
      <ProviderInsights
        {...defaultProps}
        from="2026-09-01"
        to="2026-09-30"
        month_label="Septiembre 2026"
      />,
    )

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Este mes" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos",
      {},
      { preserveScroll: true, onFinish: expect.any(Function) as () => void },
    )
  })

  it("navega una sola vez, recién al elegir el inicio y el fin del rango", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: /, 12 de octubre/ }))
    expect(routerGet).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: /, 5 de octubre/ }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-10-05&hasta=2026-10-12",
      {},
      { preserveScroll: true, onFinish: expect.any(Function) as () => void },
    )
  })

  it("toma el inicio como rango de un día si se cierra el calendario sin el fin", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: /, 12 de octubre/ }))
    await user.keyboard("{Escape}")

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-10-12&hasta=2026-10-12",
      {},
      { preserveScroll: true, onFinish: expect.any(Function) as () => void },
    )
  })

  it("genera solo con un clic y envía el período y el token CSRF", async () => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValue(response(conclusion()))
    render(<ProviderInsights {...defaultProps} />)

    expect(fetchMock).not.toHaveBeenCalled()
    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )

    await screen.findByText(/La milanesa recibe buenas valoraciones/)
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock.mock.calls[0][0]).toBe(
      "/proveedor/inicio/hallazgos/conclusiones",
    )
    expect(fetchMock.mock.calls[0][1]).toMatchObject({
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": "test-csrf-token",
      },
      body: JSON.stringify({ desde: "2026-10-01", hasta: "2026-10-31" }),
    })
    expect(screen.getByText("Generado por IA")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Período analizado: 01/10/26 – 31/10/26 · 6 reseñas consideradas",
      ),
    ).toBeInTheDocument()
    expect(
      screen.queryByText("comentario individual privado"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    ).toBeEnabled()
  })

  it("bloquea el doble clic mientras genera y permite regenerar al terminar", async () => {
    const user = userEvent.setup()
    const pending = deferred()
    fetchMock
      .mockReturnValueOnce(pending.promise)
      .mockResolvedValue(response(conclusion()))
    render(<ProviderInsights {...defaultProps} />)

    await user.dblClick(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(
      screen.getByRole("button", { name: "Generando conclusiones…" }),
    ).toBeDisabled()

    pending.resolve(response(conclusion()))
    await screen.findByText("Generado por IA")
    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
  })

  it.each([
    ["insufficient_data", 422, "Se necesitan al menos 5 reseñas válidas"],
    ["rate_limited", 429, "Alcanzaste el límite temporal"],
    ["invalid_request", 400, "El período seleccionado ya no es válido"],
    ["invalid_period", 422, "El período seleccionado ya no es válido"],
    ["timeout", 504, "La generación tardó demasiado"],
    ["invalid_response", 502, "No pudimos generar las conclusiones"],
    ["refused", 502, "No pudimos generar las conclusiones"],
    ["configuration_missing", 503, "No pudimos generar las conclusiones"],
    ["external_unavailable", 503, "No pudimos generar las conclusiones"],
  ])("muestra un mensaje seguro para %s", async (code, status, message) => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValue(
      response({ success: false, error: { code } }, status),
    )
    render(<ProviderInsights {...defaultProps} />)

    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )

    expect(await screen.findByText(new RegExp(message))).toBeInTheDocument()
    expect(screen.queryByText("Generado por IA")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    ).toBeEnabled()
  })

  it("rechaza una respuesta exitosa con un período distinto", async () => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValue(
      response(conclusion("2026-09-01", "2026-09-30")),
    )
    render(<ProviderInsights {...defaultProps} />)

    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )

    expect(
      await screen.findByText(/No pudimos generar las conclusiones/),
    ).toBeInTheDocument()
    expect(screen.queryByText("Generado por IA")).not.toBeInTheDocument()
  })

  it("borra las conclusiones al seleccionar otro período", async () => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValue(response(conclusion()))
    const { rerender } = render(<ProviderInsights {...defaultProps} />)
    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )
    await screen.findByText("Generado por IA")

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Mes pasado" }))
    expect(screen.queryByText("Generado por IA")).not.toBeInTheDocument()

    rerender(
      <ProviderInsights
        {...defaultProps}
        from="2026-09-01"
        to="2026-09-30"
        month_label="Septiembre 2026"
      />,
    )
    expect(
      screen.queryByText(/La milanesa recibe buenas valoraciones/),
    ).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    ).toBeEnabled()
  })

  it("ignora una respuesta tardía del período anterior", async () => {
    const user = userEvent.setup()
    const pending = deferred()
    fetchMock.mockReturnValueOnce(pending.promise)
    const { rerender } = render(<ProviderInsights {...defaultProps} />)
    await user.click(
      screen.getByRole("button", { name: "Generar conclusiones con IA" }),
    )

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Mes pasado" }))
    expect(fetchMock.mock.calls[0][1]?.signal?.aborted).toBe(true)

    rerender(
      <ProviderInsights
        {...defaultProps}
        from="2026-09-01"
        to="2026-09-30"
        month_label="Septiembre 2026"
      />,
    )
    pending.resolve(response(conclusion()))
    expect(
      screen.queryByText(/La milanesa recibe buenas valoraciones/),
    ).not.toBeInTheDocument()
    expect(screen.queryByText("Generado por IA")).not.toBeInTheDocument()
  })
})
