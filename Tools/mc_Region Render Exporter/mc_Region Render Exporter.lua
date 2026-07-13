-- @author mcheung
-- @version 1.0
-- @description Region Render Exporter — batch render every region as the master mix,
--              assigning mono (1ch) or stereo (2ch) per region COLOR from a GUI.
--              Uses REAPER's current render output folder + format (set once in the
--              Render window; they persist in the project). Settings restored after.

------ check dependencies (matches other MC tools) ---------------------------------
local imgui_exists = reaper.APIExists("ImGui_GetVersion")
if not imgui_exists then
    reaper.ReaPack_BrowsePackages("ReaImGui")
    reaper.ShowMessageBox("This tool requires ReaImGui: please install via ReaPack",
        "Missing extensions/packages", 0)
    return
end

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.9.3.2')

--------------------------------------------------------------------------------
-- GLOBALS
--------------------------------------------------------------------------------
ScriptVersion = "1.0"
ScriptName    = "MC_Region Render Exporter"

local proj    = 0
local EXT_SECTION = "mc_RegionRenderExporter"

-- RegionMode[regionId] = "mono" | "stereo"  (default when absent = "stereo").
-- Stored per-project inside the .rpp (project ext state), keyed by region index number.
local RegionMode = {}

-- RegionSel[regionId] = true/false  (default true = selected). Stored per-project.
local RegionSel = {}

-- Editable render options (persisted).
local OverwriteMode = "increment"  -- "increment" | "skip" | "overwrite"

local SAMPLE_RATES = { 0, 44100, 48000, 88200, 96000, 192000 }
local OVERWRITE_MODES = {
    { id = "increment", label = "Auto-increment  (name_01)" },
    { id = "skip",      label = "Skip if it exists" },
    { id = "overwrite", label = "Overwrite" },
}

local function srateLabel(v) return (v == 0) and "Project rate" or (v .. " Hz") end
local function overwriteLabel(id)
    for _, m in ipairs(OVERWRITE_MODES) do if m.id == id then return m.label end end
    return id
end

--------------------------------------------------------------------------------
-- PERSISTENCE (remember per-region mono/stereo choices in the project)
--------------------------------------------------------------------------------
local function loadRegionModes()
    RegionMode = {}
    local _, raw = reaper.GetProjExtState(proj, EXT_SECTION, "regionmodes")
    if raw and raw ~= "" then
        for id, mode in raw:gmatch("(-?%d+)=(%a+)") do
            RegionMode[tonumber(id)] = mode
        end
    end
end

local function saveRegionModes()
    local parts = {}
    for id, mode in pairs(RegionMode) do
        parts[#parts + 1] = string.format("%d=%s", id, mode)
    end
    reaper.SetProjExtState(proj, EXT_SECTION, "regionmodes", table.concat(parts, ","))
end

local function loadRegionSel()
    RegionSel = {}
    local _, raw = reaper.GetProjExtState(proj, EXT_SECTION, "regionsel")
    if raw and raw ~= "" then
        for id, v in raw:gmatch("(-?%d+)=(%d)") do
            RegionSel[tonumber(id)] = (v == "1")
        end
    end
end

local function saveRegionSel()
    local parts = {}
    for id, v in pairs(RegionSel) do
        parts[#parts + 1] = string.format("%d=%d", id, v and 1 or 0)
    end
    reaper.SetProjExtState(proj, EXT_SECTION, "regionsel", table.concat(parts, ","))
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function sanitize(name)
    if not name or name == "" then name = "region" end
    return (name:gsub('[\\/:*?"<>|]', "_"))
end

-- Collect all regions in project order.
-- Each: { pos, rgnend, name, color, id, seq }
local function scanRegions()
    local regions = {}
    local i = 0
    while true do
        local retval, isrgn, pos, rgnend, name, id, color = reaper.EnumProjectMarkers3(proj, i)
        if retval == 0 then break end
        if isrgn then
            regions[#regions + 1] = {
                pos = pos, rgnend = rgnend,
                name = (name ~= "" and name or "(unnamed)"),
                color = color, id = id, seq = #regions + 1,
            }
        end
        i = i + 1
    end
    return regions
end

local function modeOf(id)
    return RegionMode[id] or "stereo"
end

local function selectedOf(id)
    return RegionSel[id] ~= false
end

-- Convert a REAPER native color to an ImGui 0xRRGGBBAA int for swatches.
local function nativeToImGui(color)
    if color == 0 then return 0x555555FF end
    local r, g, b = reaper.ColorFromNative(color)
    return (r << 24) | (g << 16) | (b << 8) | 0xFF
end

--------------------------------------------------------------------------------
-- RENDER SETTINGS READOUT (decode current project render settings for display)
--------------------------------------------------------------------------------
local function b64decode(data)
    if not data or data == "" then return "" end
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = data:gsub('[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- little-endian 32-bit int from a byte string at 1-based offset
local function le32(s, off)
    local b1, b2, b3, b4 = s:byte(off, off + 3)
    if not b4 then return nil end
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

-- Known REAPER render format FourCCs (stored reversed in the blob).
local FMT_NAMES = {
    evaw = "WAV", ffia = "AIFF", calf = "FLAC",
    l3pm = "MP3", vggo = "OGG Vorbis", kpvw = "WavPack",
}

local FMT_EXT = {
    WAV = ".wav", AIFF = ".aiff", FLAC = ".flac",
    MP3 = ".mp3", ["OGG Vorbis"] = ".ogg", WavPack = ".wv",
}

local function getRenderInfo()
    local info = {}

    local srate = reaper.GetSetProjectInfo(proj, "RENDER_SRATE", 0, false)
    info.srateRaw = math.floor(srate or 0)
    info.srate = (srate and srate > 0) and string.format("%d Hz", srate) or "Project rate"

    local norm = reaper.GetSetProjectInfo(proj, "RENDER_NORMALIZE", 0, false)
    -- bit 0 of RENDER_NORMALIZE is the actual enable flag; higher bits hold
    -- target/method values that can be non-zero even when normalization is off.
    info.normalize = (norm and (math.floor(norm) & 1) == 1) and "On" or "Off"

    local dith = reaper.GetSetProjectInfo(proj, "RENDER_DITHER", 0, false)
    info.dither = (dith and (math.floor(dith) & 1) == 1) and "On" or "Off"

    local _, dir = reaper.GetSetProjectInfo_String(proj, "RENDER_FILE", "", false)
    info.dir = dir or ""

    local _, blob = reaper.GetSetProjectInfo_String(proj, "RENDER_FORMAT", "", false)
    local raw = b64decode(blob)
    local fourcc = raw:sub(1, 4)
    info.format = FMT_NAMES[fourcc] or (fourcc ~= "" and fourcc:reverse() or "?")
    info.ext = FMT_EXT[info.format]
    if fourcc == "evaw" or fourcc == "ffia" then
        local bd = le32(raw, 5)
        if bd and bd > 0 and bd <= 64 then info.bitdepth = bd .. " bit" end
    end

    return info
end

--------------------------------------------------------------------------------
-- RENDER
--------------------------------------------------------------------------------

-- Resolve the output filename base according to the overwrite mode.
-- Returns the pattern to use, or nil to skip this region.
local function resolveTargetName(dir, base, ext, mode)
    if not ext then return base end  -- unknown format: can't check, just render
    local root = dir:gsub("[\\/]+$", "")
    local function exists(n) return reaper.file_exists(root .. "/" .. n .. ext) end

    if not exists(base) then return base end
    if mode == "skip" then return nil end
    if mode == "overwrite" then
        os.remove(root .. "/" .. base .. ext)
        return base
    end
    -- increment
    local i = 1
    while i <= 999 do
        local cand = string.format("%s_%02d", base, i)
        if not exists(cand) then return cand end
        i = i + 1
    end
    return base
end

local function renderAll(regions)
    local ri = getRenderInfo()
    if ri.dir == "" then
        reaper.MB(
            "No render output directory is set.\n\n" ..
            "Open File > Render, set your output Directory and Format once, close the " ..
            "window (settings save in the project), then run this tool again.",
            ScriptName, 0)
        return
    end

    reaper.Undo_BeginBlock()

    -- Save current render settings to restore afterward.
    local s_settings = reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", 0, false)
    local s_bounds  = reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", 0, false)
    local s_start   = reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", 0, false)
    local s_end     = reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", 0, false)
    local s_chans   = reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", 0, false)
    local _, s_patt = reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", "", false)

    -- Force Source = Master mix so custom per-region time bounds are honored
    -- (a Region Render Matrix source would otherwise render all regions each pass).
    reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", 0, true)

    local rendered, skipped = 0, 0
    for _, r in ipairs(regions) do
        if selectedOf(r.id) then
            local pat = resolveTargetName(ri.dir, sanitize(r.name), ri.ext, OverwriteMode)
            if pat then
                local channels = (modeOf(r.id) == "mono") and 1 or 2
                reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", 0, true)   -- custom time bounds
                reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", r.pos, true)
                reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", r.rgnend, true)
                reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", channels, true)
                reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", pat, true)
                reaper.Main_OnCommand(42230, 0)  -- render, auto-close dialog
                rendered = rendered + 1
            else
                skipped = skipped + 1
            end
        end
    end

    -- Restore.
    reaper.GetSetProjectInfo(proj, "RENDER_SETTINGS", s_settings, true)
    reaper.GetSetProjectInfo(proj, "RENDER_BOUNDSFLAG", s_bounds, true)
    reaper.GetSetProjectInfo(proj, "RENDER_STARTPOS", s_start, true)
    reaper.GetSetProjectInfo(proj, "RENDER_ENDPOS", s_end, true)
    reaper.GetSetProjectInfo(proj, "RENDER_CHANNELS", s_chans, true)
    reaper.GetSetProjectInfo_String(proj, "RENDER_PATTERN", s_patt, true)

    reaper.Undo_EndBlock("Render regions mono/stereo by color", -1)

    if skipped > 0 then
        reaper.MB(string.format("Rendered %d region(s).\nSkipped %d that already existed.",
            rendered, skipped), ScriptName, 0)
    end
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------
local ctx        = reaper.ImGui_CreateContext(ScriptName)
local font       = reaper.ImGui_CreateFont('Cleon Sans', 15)
local menufont   = reaper.ImGui_CreateFont('Cleon Sans', 28)
local font_small = reaper.ImGui_CreateFont('Cleon Sans', 12)
local regionfont = reaper.ImGui_CreateFont('Cleon Sans', 13)
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, menufont)
reaper.ImGui_Attach(ctx, font_small)
reaper.ImGui_Attach(ctx, regionfont)

local guiW, guiH = 675, 768
do
    local s = reaper.GetExtState(EXT_SECTION, "winsize")
    local w, h = s:match("(%d+),(%d+)")
    if w and h then guiW, guiH = tonumber(w), tonumber(h) end
end

loadRegionModes()
loadRegionSel()
do
    local om = reaper.GetExtState(EXT_SECTION, "overwrite")
    if om ~= "" then OverwriteMode = om end
end

local function setAllModes(regions, mode)
    for _, r in ipairs(regions) do RegionMode[r.id] = mode end
    saveRegionModes()
end

local function setAllSelected(regions, val)
    for _, r in ipairs(regions) do RegionSel[r.id] = val end
    saveRegionSel()
end

local function drawRegionRow(r)
    reaper.ImGui_TableNextRow(ctx)

    -- checkbox + swatch + region name
    reaper.ImGui_TableSetColumnIndex(ctx, 0)
    do
        local schg, snew = reaper.ImGui_Checkbox(ctx, "##sel" .. r.seq, selectedOf(r.id))
        if schg then RegionSel[r.id] = snew; saveRegionSel() end
    end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_ColorButton(ctx, "##sw" .. r.seq, nativeToImGui(r.color),
        reaper.ImGui_ColorEditFlags_NoTooltip(), 14, 14)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_AlignTextToFramePadding(ctx)
    reaper.ImGui_PushFont(ctx, regionfont)
    reaper.ImGui_Text(ctx, r.name)
    reaper.ImGui_PopFont(ctx)

    -- mono / stereo radios
    reaper.ImGui_TableSetColumnIndex(ctx, 1)
    local mode = modeOf(r.id)
    if reaper.ImGui_RadioButton(ctx, "Mono##" .. r.seq, mode == "mono") then
        RegionMode[r.id] = "mono"; saveRegionModes()
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_RadioButton(ctx, "Stereo##" .. r.seq, mode == "stereo") then
        RegionMode[r.id] = "stereo"; saveRegionModes()
    end
end

local function loop()
    PushTheme()
    local FLTMIN = reaper.ImGui_NumericLimits_Float()

    local flags = reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, guiW, guiH, reaper.ImGui_Cond_Once())
    reaper.ImGui_PushFont(ctx, font)

    local visible, open = reaper.ImGui_Begin(ctx, ScriptName .. ' ' .. ScriptVersion, true, flags)
    if visible then
        local regions = scanRegions()
        local ri = getRenderInfo()
        local hasFolder = (ri.dir ~= "")

        -- ---------- Header ----------
        reaper.ImGui_PushFont(ctx, menufont)
        reaper.ImGui_Text(ctx, "Region Render Exporter")
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_TextColored(ctx, 0x9A9A9AFF, "Batch-render regions to mono or stereo, per region")
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_Dummy(ctx, 0, 4)

        -- ---------- Render Settings ----------
        reaper.ImGui_SeparatorText(ctx, 'Render Settings')

        if not hasFolder then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF6E59FF)
            reaper.ImGui_TextWrapped(ctx,
                "No render folder set.  Type a path below (or use Browse).")
            reaper.ImGui_PopStyleColor(ctx)
        else
            reaper.ImGui_PushFont(ctx, font_small)
            local fmtLine = ri.format .. (ri.bitdepth and ("  " .. ri.bitdepth) or "")
            reaper.ImGui_TextColored(ctx, 0xC8C8C8FF, string.format(
                "%s      Normalize: %s      Dither: %s", fmtLine, ri.normalize, ri.dither))
            reaper.ImGui_PopFont(ctx)
        end

        reaper.ImGui_Dummy(ctx, 0, 2)

        -- editable controls
        if reaper.ImGui_BeginTable(ctx, "edit", 2, reaper.ImGui_TableFlags_None()) then
            reaper.ImGui_TableSetupColumn(ctx, "k", reaper.ImGui_TableColumnFlags_WidthFixed(), 92)
            reaper.ImGui_TableSetupColumn(ctx, "v", reaper.ImGui_TableColumnFlags_WidthStretch())

            -- Output folder (editable)
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableSetColumnIndex(ctx, 0)
            reaper.ImGui_AlignTextToFramePadding(ctx); reaper.ImGui_TextDisabled(ctx, "Output folder")
            reaper.ImGui_TableSetColumnIndex(ctx, 1)
            local hasBrowse = reaper.APIExists("JS_Dialog_BrowseForFolder")
            reaper.ImGui_SetNextItemWidth(ctx, hasBrowse and -72 or -FLTMIN)
            local fchg, fnew = reaper.ImGui_InputText(ctx, "##folder", ri.dir)
            if fchg then reaper.GetSetProjectInfo_String(proj, "RENDER_FILE", fnew, true) end
            if hasBrowse then
                reaper.ImGui_SameLine(ctx)
                if reaper.ImGui_Button(ctx, "Browse", -FLTMIN, 0) then
                    local ok, folder = reaper.JS_Dialog_BrowseForFolder("Choose render output folder", ri.dir)
                    if ok and folder and folder ~= "" then
                        reaper.GetSetProjectInfo_String(proj, "RENDER_FILE", folder, true)
                    end
                end
            end

            -- Sample rate
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableSetColumnIndex(ctx, 0)
            reaper.ImGui_AlignTextToFramePadding(ctx); reaper.ImGui_TextDisabled(ctx, "Sample rate")
            reaper.ImGui_TableSetColumnIndex(ctx, 1)
            reaper.ImGui_SetNextItemWidth(ctx, -FLTMIN)
            if reaper.ImGui_BeginCombo(ctx, "##srate", srateLabel(ri.srateRaw)) then
                for _, v in ipairs(SAMPLE_RATES) do
                    if reaper.ImGui_Selectable(ctx, srateLabel(v), v == ri.srateRaw) then
                        reaper.GetSetProjectInfo(proj, "RENDER_SRATE", v, true)
                    end
                end
                reaper.ImGui_EndCombo(ctx)
            end

            -- Overwrite behavior
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableSetColumnIndex(ctx, 0)
            reaper.ImGui_AlignTextToFramePadding(ctx); reaper.ImGui_TextDisabled(ctx, "If file exists")
            reaper.ImGui_TableSetColumnIndex(ctx, 1)
            reaper.ImGui_SetNextItemWidth(ctx, -FLTMIN)
            if reaper.ImGui_BeginCombo(ctx, "##ow", overwriteLabel(OverwriteMode)) then
                for _, m in ipairs(OVERWRITE_MODES) do
                    if reaper.ImGui_Selectable(ctx, m.label, m.id == OverwriteMode) then
                        OverwriteMode = m.id
                        reaper.SetExtState(EXT_SECTION, "overwrite", OverwriteMode, true)
                    end
                end
                reaper.ImGui_EndCombo(ctx)
            end

            reaper.ImGui_EndTable(ctx)
        end

        -- ---------- Regions ----------
        reaper.ImGui_Dummy(ctx, 0, 4)
        reaper.ImGui_SeparatorText(ctx, 'Regions')

        if #regions == 0 then
            reaper.ImGui_PushFont(ctx, font_small)
            reaper.ImGui_TextColored(ctx, 0x9A9A9AFF, "No regions found in this project.")
            reaper.ImGui_PopFont(ctx)
        else
            if reaper.ImGui_SmallButton(ctx, "Select All") then setAllSelected(regions, true) end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_SmallButton(ctx, "Select None") then setAllSelected(regions, false) end
            reaper.ImGui_SameLine(ctx); reaper.ImGui_Dummy(ctx, 12, 0); reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_SmallButton(ctx, "All Mono") then setAllModes(regions, "mono") end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_SmallButton(ctx, "All Stereo") then setAllModes(regions, "stereo") end
            reaper.ImGui_Dummy(ctx, 0, 2)

            local childVisible = reaper.ImGui_BeginChild(ctx, "regionlist", 0, 300)
            if childVisible then
                if reaper.ImGui_BeginTable(ctx, "regions", 2,
                    reaper.ImGui_TableFlags_RowBg() | reaper.ImGui_TableFlags_BordersInnerH()) then
                    reaper.ImGui_TableSetupColumn(ctx, "Region", reaper.ImGui_TableColumnFlags_WidthStretch())
                    reaper.ImGui_TableSetupColumn(ctx, "Mode", reaper.ImGui_TableColumnFlags_WidthFixed(), 148)
                    for _, r in ipairs(regions) do drawRegionRow(r) end
                    reaper.ImGui_EndTable(ctx)
                end
            end
            reaper.ImGui_EndChild(ctx)
        end

        -- ---------- Action bar ----------
        local selCount, monoCount, stereoCount = 0, 0, 0
        for _, r in ipairs(regions) do
            if selectedOf(r.id) then
                selCount = selCount + 1
                if modeOf(r.id) == "mono" then monoCount = monoCount + 1
                else stereoCount = stereoCount + 1 end
            end
        end

        reaper.ImGui_Dummy(ctx, 0, 2)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_TextColored(ctx, 0xC8C8C8FF, string.format(
            "%d of %d selected      %d mono      %d stereo", selCount, #regions, monoCount, stereoCount))
        reaper.ImGui_PopFont(ctx)

        local canRender = (selCount > 0) and hasFolder
        if not canRender then reaper.ImGui_BeginDisabled(ctx) end
        local btnLabel = string.format("Render %d Region%s", selCount, selCount == 1 and "" or "s")
        if reaper.ImGui_Button(ctx, btnLabel, -FLTMIN, 44) then
            renderAll(regions)
        end
        if not canRender then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_Dummy(ctx, 0, 1)
        reaper.ImGui_PushFont(ctx, font_small)
        reaper.ImGui_TextColored(ctx, 0x6E6E6EFF, "developed by Michael Cheung")
        reaper.ImGui_PopFont(ctx)

        -- Remember the window size so it becomes the default next launch.
        local ww, wh = reaper.ImGui_GetWindowSize(ctx)
        ww, wh = math.floor(ww), math.floor(wh)
        if ww ~= guiW or wh ~= guiH then
            guiW, guiH = ww, wh
            reaper.SetExtState(EXT_SECTION, "winsize", guiW .. "," .. wh, true)
        end

        reaper.ImGui_End(ctx)
    end

    PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then reaper.defer(loop) end
end

--------------------------------------------------------------------------------
-- THEME  (matches other MC tools)
--------------------------------------------------------------------------------
function PushTheme()
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_Alpha(),                       1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_DisabledAlpha(),               0.6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),               8, 8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),              12)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(),            1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowMinSize(),               32, 32)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),            0, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),                3.5, 3.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),             1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),                 8, 5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),            4, 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_IndentSpacing(),               21)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),                 4, 2)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize(),               14)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),           9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(),                 16)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),                 4)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBorderSize(),               0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarBorderSize(),            1)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersAngle(),     0.610865)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersTextAlign(), 0.5, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(),             0.5, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(),         0, 0)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(),     1.8)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(),          0, 0.5)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        20, 3)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                9)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        19, 0)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),                      0xFFFFFFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),              0x808080FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),                  0x1A1A1AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),                   0x00000000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),                   0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),                    0x3A3737CC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(),              0x0000001A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),                   0x1F1F1FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),            0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),             0x21222DFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),                   0x0A0A0ABB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),             0x0A0A0AC6)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),          0x0A0A0AC7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),                 0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),               0x1F1F1FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),             0x4F4F4FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(),      0x696969FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),       0x828282FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),                 0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),                0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),          0x2E2EAEFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),                    0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),             0x3434C7FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),              0x3434C7FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),                    0x1E1E1EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),             0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),              0x28289CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),                 0x2A2A2AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(),          0x1A66BFC7)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(),           0x1A66BFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),                0x4296FA33)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),         0x4296FAAB)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),          0x4296FAF2)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),                0x4296FACC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                       0x2E5994DC)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(),               0x3369ADFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(),       0x4296FAFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmed(),                 0x111A26F8)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelected(),         0x23436CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelectedOverline(), 0x808080FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(),            0xAC373FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingEmptyBg(),            0x333333FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLines(),                 0x9C9C9CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLinesHovered(),          0xFF6E59FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(),             0xE6B300FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogramHovered(),      0xFF9900FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableHeaderBg(),             0x303033FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderStrong(),         0x4F4F59FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderLight(),          0x3B3B40FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBg(),                0x00000000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBgAlt(),             0xFFFFFF0F)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),            0x4296FA59)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(),            0xFFFF00E6)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavHighlight(),              0x4296FAFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingHighlight(),     0xFFFFFFB3)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingDimBg(),         0xCCCCCC33)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ModalWindowDimBg(),          0xCCCCCC59)
end

function PopTheme()
    reaper.ImGui_PopStyleVar(ctx, 35)
    reaper.ImGui_PopStyleColor(ctx, 57)
end

reaper.defer(loop)
