package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'
local ctx = ImGui.CreateContext('My script')

local function loop()
  local visible, open = ImGui.Begin(ctx, 'My window', true)
  if visible then
    ImGui.Text(ctx, 'Hello World!')
    ImGui.End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)