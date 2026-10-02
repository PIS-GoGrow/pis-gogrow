import "@testing-library/jest-dom/vitest"

import { cleanup, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import PublishBar from "./publish-bar"

afterEach(cleanup)

describe("PublishBar", () => {
  const defaultProps = {
    dateLabel: "Lunes 23 de Septiembre",
    statusLabel: "Publicado",
    canPublish: false,
    canEdit: true,
    selectedCount: 1,
    processing: false,
    onPublish: vi.fn(),
    onEdit: vi.fn(),
  }

  it("muestra el botón de editar menú cuando la fecha está publicada y es editable", async () => {
    const user = userEvent.setup()
    const onEdit = vi.fn()

    render(
      <PublishBar
        {...defaultProps}
        canPublish={false}
        canEdit={true}
        onEdit={onEdit}
      />,
    )

    const editButton = screen.getByRole("button", { name: /editar menú/i })
    expect(editButton).toBeInTheDocument()

    await user.click(editButton)
    expect(onEdit).toHaveBeenCalledOnce()
  })

  it("no muestra el botón de editar menú cuando no está habilitada la edición", () => {
    render(<PublishBar {...defaultProps} canPublish={false} canEdit={false} />)

    expect(
      screen.queryByRole("button", { name: /editar menú/i }),
    ).not.toBeInTheDocument()
  })

  it("muestra el botón de publicar en lugar de editar cuando se está editando o publicando", () => {
    render(
      <PublishBar
        {...defaultProps}
        statusLabel="Editando menú publicado"
        canPublish={true}
        canEdit={false}
      />,
    )

    expect(
      screen.getByRole("button", { name: /publicar menú/i }),
    ).toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: /editar menú/i }),
    ).not.toBeInTheDocument()
  })

  it("deshabilita el botón de publicar si no hay platos seleccionados o si está procesando", () => {
    const { rerender } = render(
      <PublishBar
        {...defaultProps}
        canPublish={true}
        selectedCount={0}
        processing={false}
      />,
    )

    expect(
      screen.getByRole("button", { name: /publicar menú/i }),
    ).toBeDisabled()

    rerender(
      <PublishBar
        {...defaultProps}
        canPublish={true}
        selectedCount={2}
        processing={true}
      />,
    )

    expect(
      screen.getByRole("button", { name: /publicando\.\.\./i }),
    ).toBeDisabled()
  })
})
