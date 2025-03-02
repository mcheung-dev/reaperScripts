
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
local proj = 0
reaper.defer(loop)