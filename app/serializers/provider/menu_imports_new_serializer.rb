# frozen_string_literal: true

class Provider::MenuImportsNewSerializer < ApplicationSerializer
  AGENDA = "{ mode: 'none' | 'single' | 'weekly' | 'range'; weekdays: number[]; date: string | null; starts_on: string | null; ends_on: string | null; amount: number | null }"
  OPTION_GROUP = "{ name: string; options: string[]; limit: number; required: boolean }"
  ENTRY = "{ number: number; name: string; description: string; price: number | null; option_groups: #{OPTION_GROUP}[]; errors: string[] }"
  SAVED_MENU = "{ id: number; name: string; confirmed_orders: number; agenda: #{AGENDA} }"
  PREVIEW = "{ id: string; filename: string | null; error: string | null; entries: #{ENTRY}[] }"

  typelize template_path: :string, formats: "string[]", max_rows: :number, max_size_mb: :number,
           today: :string, maximum_publish_date: :string, saved_menus: "#{SAVED_MENU}[]",
           preview: "#{PREVIEW} | null", imported: "{ count: number } | null",
           row_errors: "Record<string, string[]>"
  attributes :template_path, :formats, :max_rows, :max_size_mb, :today, :maximum_publish_date,
             :saved_menus, :preview, :imported, :row_errors
end
