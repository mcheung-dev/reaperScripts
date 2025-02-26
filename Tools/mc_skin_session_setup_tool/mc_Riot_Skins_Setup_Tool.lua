-- @author mcheung
-- @version 1.1
-- @provides 
--     [nomain] Functions/*.lua
------check to see if user has required dependencies
local imgui_exists = reaper.APIExists("ImGui_GetVersion")
local sws_exists = reaper.APIExists("CF_GetSWSVersion")
local js_exists = reaper.APIExists("JS_ReaScriptAPI_Version")

if not imgui_exists or not sws_exists or not js_exists then
  local open_reapack = false

  local msg = "This tool requires the following extensions/packages to work:\n"
  if not sws_exists then
    msg = msg .. "SWS Extension - https://www.sws-extension.org\n"
  end
  if not js_exists then
    msg = msg .. "js_ReaScriptAPI: please install via ReaPack\n"
    open_reapack = true
  end
  if not imgui_exists then
    msg = msg .. "ReaImGui: please install via ReaPack\n"
    open_reapack = true
  end

  if open_reapack then reaper.ReaPack_BrowsePackages("") end

  reaper.ShowMessageBox(msg, "Missing extensions/packages", 0)

  goto eof
end



--- global variables 
ScriptVersion = "1.0"
ScriptName = 'MC_Skin Import Tool'

--- load functions
dofile(reaper.GetResourcePath() ..
    '/Scripts/ReaTeam Extensions/API/imgui.lua')
('0.9.3.2') -- current version at time of script dev, forces imgui version in case of function updates that will break logic
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path

require('Functions/User Interface')


local proj = 0
reaper.defer(loop)

reaper.set_action_options(3)

::eof::