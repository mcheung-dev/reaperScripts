-- @author mcheung
-- @version 1.0
-- @description Render every region as the master mix, choosing mono (1ch) or stereo (2ch)
--              per region based on the region's COLOR. Uses REAPER's current render
--              output folder + format (set them once in the Render window, they persist
--              in the project). Original render settings are restored afterward.

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------

-- Set this to TRUE, run the script, and it will print every region's name + color
-- number to the ReaScript console. Copy the number of a mono-colored region into
-- MONO_COLOR below, then set DETECT_MODE back to false.
local DETECT_MODE = false

-- The native color value that marks a MONO region (grab it via DETECT_MODE above).
-- Every region NOT matching this color is treated as STEREO.
local MONO_COLOR = 0

-- If you prefer the opposite logic (a specific color = STEREO, everything else mono),
-- set this to true and put the stereo color in MONO_COLOR instead.
local INVERT_LOGIC = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local proj = 0

local function msg(s)
    reaper.ShowConsoleMsg(tostring(s) .. "\n")
end

-- Make a region name safe to use as a filename.
local function sanitize(name)
    if not name or name == "" then name = "region" end
    return (name:gsub('[\\/:*?"<>|]', "_"))
end

-- Collect all regions: { {pos=, rgnend=, name=, color=} , ... }
local function collectRegions()
    local regions = {}
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, name, _, color = reaper.EnumProjectMarkers3(proj, i)
        if retval == 0 then break end
        if isrgn then
            regions[#regions + 1] = { pos = pos, rgnend = rgnend, name = name, color = color }
        end
        i = i + 1
    end
    return regions
end

--------------------------------------------------------------------------------
-- DETECT MODE: list every region + color, then stop.
--------------------------------------------------------------------------------

if DETECT_MODE then
    reaper.ClearConsole()
    local regions = collectRegions()
    if #regions == 0 then
        msg("No regions found in project.")
        return
    end
    msg("Region colors (paste the mono color number into MONO_COLOR):\n")
    for idx, r in ipairs(regions) do
        local colorStr = tostring(r.color)
        local rgbStr = ""
        if r.color ~= 0 then
            local cr, cg, cb = reaper.ColorFromNative(r.color)
            rgbStr = string.format("  (R:%d G:%d B:%d)", cr, cg, cb)
        else
            rgbStr = "  (no custom color)"
        end
        msg(string.format("%2d.  color = %-12s%s   name = %s", idx, colorStr, rgbStr, r.name))
    end
    return
end

--------------------------------------------------------------------------------
-- RENDER
--------------------------------------------------------------------------------

local regions = collectRegions()
if #regions == 0 then
    reaper.MB("No regions found in this project.", "Render Regions by Color", 0)
    return
end

-- Sanity check: output directory should be set in the current render settings.
local _, renderDir = reaper.GetSetProjectInfo_String(proj, "RENDER_FILE", "", false)
if renderDir == "" then
    reaper.MB(
        "No render output directory is set.\n\n" ..
        "Open File > Render, set your output Directory and Format once, close the " ..
        "window (settings are saved in the project), then run this script again.",
        "Render Regions by Color", 0)
    return
end

reaper.Undo_BeginBlock()

-- Save current render settings so we can restore them afterward.
local saved_settings   = reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", 0, false)
local saved_boundsFlag = reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", 0, false)
local saved_startPos   = reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", 0, false)
local saved_endPos     = reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", 0, false)
local saved_channels   = reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", 0, false)
local _, saved_pattern = reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", "", false)

-- Force Source = Master mix so custom per-region time bounds are honored (a Region
-- Render Matrix source would otherwise render all regions on every pass).
reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", 0, true)

-- Render each region individually with custom time bounds so we can vary channels.
for _, r in ipairs(regions) do
    local isMono = (r.color == MONO_COLOR)
    if INVERT_LOGIC then isMono = not isMono end
    local channels = isMono and 1 or 2

    reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", 0, true)          -- custom time bounds
    reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", r.pos, true)
    reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", r.rgnend, true)
    reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", channels, true)
    reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", sanitize(r.name), true)

    -- Render project with most recent settings and auto-close the dialog.
    reaper.Main_OnCommand(42230, 0)
end

-- Restore original render settings.
reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", saved_settings, true)
reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", saved_boundsFlag, true)
reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", saved_startPos, true)
reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", saved_endPos, true)
reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", saved_channels, true)
reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", saved_pattern, true)

reaper.Undo_EndBlock("Render regions mono/stereo by color", -1)
