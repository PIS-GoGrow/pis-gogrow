# frozen_string_literal: true

module Animations
  # Las hojas entran deslizándose: en CI el clic caía mientras se movían.
  def without_animations
    page.execute_script(<<~JS)
      const style = document.createElement("style")
      style.textContent = "*, *::before, *::after { animation: none !important; transition: none !important; }"
      document.head.appendChild(style)
    JS
  end
end

RSpec.configure do |config|
  config.include Animations, type: :system
end
