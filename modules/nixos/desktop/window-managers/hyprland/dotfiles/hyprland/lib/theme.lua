local default_colors = require("colors")
local light = require("colors-light")
local dark = require("colors-dark")

local M = {}

M.current = nil
M.colors = default_colors

function M.apply(mode)
  local colors = mode == "light" and light or dark

  M.current = mode
  M.colors = colors

  hl.config({
    general = {
      col = {
        inactive_border = colors.border,
        active_border = colors.primary,
        nogroup_border = colors.border,
        nogroup_border_active = colors.primary,
      },
    },
    group = {
      col = {
        border_inactive = colors.border,
        border_active = colors.borderSecondary,
        border_locked_inactive = colors.border,
        border_locked_active = colors.borderSecondary,
      },
      groupbar = {
        text_color = colors.text,
        col = {
          inactive = colors.secondary40,
          active = colors.secondary,
          locked_inactive = colors.tertiary40,
          locked_active = colors.tertiary,
        },
      },
    },
    decoration = {
      shadow = {
        color = colors.shadow80,
        color_inactive = colors.shadow66,
      },
      blur = {
        brightness = mode == "light" and 1.0 or 0.9,
      },
    },
    misc = {
      background_color = colors.background,
    },
  })
end

function M.toggle(mode)
  if mode == "dark" or mode == "light" then
    M.apply(mode)
  else
    M.apply(M.current == "dark" and "light" or "dark")
  end
end

return M
