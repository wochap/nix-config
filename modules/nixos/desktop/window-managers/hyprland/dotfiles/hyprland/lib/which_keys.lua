-- Emit the currently held standard modifier mask for passive shell overlays.
-- Bindings are universal so releases continue to be observed inside submaps,
-- and transparent/non-consuming so normal compositor and client input remains
-- unaffected.

local M = {}

local modifiers = {
  { mask = 64, keys = { "SUPER_L", "SUPER_R" } },
  { mask = 4, keys = { "Control_L", "Control_R" } },
  { mask = 8, keys = { "ALT_L", "ALT_R" } },
  { mask = 1, keys = { "SHIFT_L", "SHIFT_R" } },
}

local pressed = {}

local function encode(value)
  local encoded = tostring(value):gsub("([^%w_.~-])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
  return encoded
end

local function emit_hint(action, submap, key, description)
  local parts = { "which_keys_hint", action, encode(submap) }
  if key ~= nil then
    table.insert(parts, encode(key))
  end
  if description ~= nil then
    table.insert(parts, encode(description))
  end
  hl.dispatch(hl.dsp.event(table.concat(parts, ">>")))
end

local function emit()
  local mask = 0
  for _, modifier in ipairs(modifiers) do
    for _, key in ipairs(modifier.keys) do
      if pressed[key] then
        mask = mask + modifier.mask
        break
      end
    end
  end
  hl.dispatch(hl.dsp.event("which_keys>>" .. mask))
end

local options = {
  non_consuming = true,
  transparent = true,
  ignore_mods = true,
  submap_universal = true,
}

function M.setup()
  for _, modifier in ipairs(modifiers) do
    for _, key in ipairs(modifier.keys) do
      hl.bind(key, function()
        pressed[key] = true
        emit()
      end, options)
      hl.bind(key, function()
        pressed[key] = nil
        emit()
      end, {
        release = true,
        non_consuming = true,
        transparent = true,
        ignore_mods = true,
        submap_universal = true,
      })
    end
  end
end

-- Add or replace a runtime-only hint. These hints complement the bindings
-- reported by `hyprctl binds` and are useful for stateful submaps.
function M.add_hint(submap, key, description)
  assert(type(submap) == "string" and submap ~= "", "which-keys submap is required")
  assert(type(key) == "string" and key ~= "", "which-keys hint key is required")
  emit_hint("set", submap, key, description or "")
end

function M.remove_hint(submap, key)
  assert(type(submap) == "string" and submap ~= "", "which-keys submap is required")
  assert(type(key) == "string" and key ~= "", "which-keys hint key is required")
  emit_hint("remove", submap, key)
end

function M.clear_hints(submap)
  assert(type(submap) == "string" and submap ~= "", "which-keys submap is required")
  emit_hint("clear", submap)
end

return M
