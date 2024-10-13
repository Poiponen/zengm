# This code is a React component that generates a confetti effect using a canvas.
# It imports a library for generating confetti and uses hooks for managing state and side effects.

def hex_to_rgb(hex)
  # Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  shorthand_regex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
  hex = hex.gsub(shorthand_regex) { |m, r, g, b| r + r + g + g + b + b }

  result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.match(hex)
  if result
    [
      result[1].to_i(16),
      result[2].to_i(16),
      result[3].to_i(16)
    ]
  else
    nil
  end
end

class Confetti
  attr_accessor :colors, :clicked

  def initialize(colors = nil)
    @colors = colors
    @clicked = false
    @canvas_id = "confetti"
    setup_confetti
  end

  def setup_confetti
    confetti_settings = {
      target: @canvas_id,
      colors: @colors ? @colors.map { |color| hex_to_rgb(color) } : nil,
      rotate: true,
      size: 2
    }
    @confetti_generator = ConfettiGenerator.new(confetti_settings)
    @confetti_generator.render
  end

  def click_handler
    @clicked = true
    clear_confetti
  end

  def clear_confetti
    @confetti_generator.clear if @confetti_generator
  end

  def render
    return nil if @clicked

    "<canvas id='#{@canvas_id}' onclick='click_handler()'></canvas>"
  end
end
