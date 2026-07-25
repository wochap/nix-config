-- dynamic active border color, ported from scripts/hyprland-socket.sh
-- single tiling window (or monocle, no floating) -> borderSecondary
-- monocle -> secondary
-- otherwise -> primary

local theme = require("hyprland.lib.theme")

local M = {}

function M.setup()
  hl.on("window.active", function()
    local colors = theme.colors

    local ws = hl.get_active_workspace()
    if not ws then
      return
    end
    local monitor = ws.monitor

    local tiling, floating = 0, 0
    for _, w in ipairs(hl.get_windows({ workspace = ws, monitor = monitor, mapped = true })) do
      if not w.hidden then
        if w.floating then
          floating = floating + 1
        else
          tiling = tiling + 1
        end
      end
    end

    local is_monocle = ws.tiled_layout == "monocle"

    local color
    if (tiling == 1 or is_monocle) and floating == 0 then
      color = colors.borderSecondary
    elseif is_monocle then
      color = colors.secondary
    else
      color = colors.primary
    end

    hl.config({ general = { col = { active_border = color } } })
  end)
end

return M
