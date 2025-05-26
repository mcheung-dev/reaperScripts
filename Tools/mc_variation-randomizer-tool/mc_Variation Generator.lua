-- @author mcheung
-- @version 1.1
-- @provides 
--     [nomain] Functions/*.lua
--     [nomain] Presets/*.json

------check to see if user has required dependencies need for tool to run
local imgui_exists = reaper.APIExists("ImGui_GetVersion")
local js_exists = reaper.APIExists("JS_ReaScriptAPI_Version")

if not imgui_exists or not js_exists then
  local open_reapack = false

  local msg = "This tool requires the following extensions/packages to work:\n"
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

  return
end
--- global variables 
ScriptVersion = "1.0"
ScriptName = 'MC_Variation Generator Tool'
Settings = {
    pos = {
        min = 0, 
        max = 0,
    },
    rate = { -- Rate cannot be 0
        min = 1,
        max = 1,
    },
    pitch = {
        min = 0,
        max = 0,
    },
    
    vol = { -- in dB
        min = 0,
        max = 0,
    },

    content = {
        min = 0,
        max = 0,
    
    },

    takes = false,

    region = false
}

--- load functions
dofile(reaper.GetResourcePath() ..
    '/Scripts/ReaTeam Extensions/API/imgui.lua')
('0.9.3.2') -- current version at time of script dev, forces imgui version in case of function updates that will break logic
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require('Functions/User Interface')
require('Functions/Randomize Function')
require('Functions/General Functions')


--- presets
presets_path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .. '/Presets/presets'
json = require('Functions/json')
require('Functions/Presets')
SavePreset(presets_path, 'Default') -- create default preset
proj = 0 -- Make proj a global variable so it's accessible in other files

reaper.defer(loop)
reaper.set_action_options(3) -- allows re-triggers of script to close existing instance and start new one