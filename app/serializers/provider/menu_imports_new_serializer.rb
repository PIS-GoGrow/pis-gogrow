# frozen_string_literal: true

class Provider::MenuImportsNewSerializer < ApplicationSerializer
  typelize template_path: :string, max_rows: :number, max_size_mb: :number,
           preview: "{ error: string | null; filename: string | null; can_import: boolean; entries: { number: number; name: string; action: 'create' | 'update'; errors: string[] }[] } | null"
  attributes :template_path, :max_rows, :max_size_mb, :preview
end
