export default function Heading({
  title,
  description,
  eyebrow,
}: {
  title: string
  description?: string
  eyebrow?: string
}) {
  return (
    <div className="mb-8 space-y-0.5">
      {eyebrow && (
        <p className="text-muted-foreground text-xs font-semibold tracking-wider uppercase">
          {eyebrow}
        </p>
      )}
      <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
      {description && (
        <p className="text-muted-foreground text-sm">{description}</p>
      )}
    </div>
  )
}
