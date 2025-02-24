-- @noindex
function CreateSubprojects()-- create subprojects with regions 
    local track_count = reaper.CountTracks(0)

    -- Deselect all tracks first
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

    -- Select all tracks
    for i = 1, track_count - 1 do

        local track = reaper.GetTrack(0, i)

        reaper.SetTrackSelected(track, true)
        reaper.Main_OnCommand(41997, 0) -- create subproject
        reaper.Main_OnCommand(40297, 0) -- deselect all tracks
    end


    function count_project_tabs()
        local count = 0
        while reaper.EnumProjects(count, "") do
            count = count + 1
        end
        return count
    end


    local base_path = "T:/p4/depot/lol/_AUDIODEV_/Wwise/Originals/SFX/Champions/"

    local project_tab_count = count_project_tabs()

    for i = 1, project_tab_count -1 do --- it is for i=1 because we don't want to create regions in main proj
        --- create subprojects 
        reaper.Main_OnCommand(40861,0) --- go to next project tab
        reaper.SelectAllMediaItems(0, true)

        -- Get first item name for path components
        local item_name = ""
        local item = reaper.GetSelectedMediaItem(0, 0)
        if item then
            local take = reaper.GetActiveTake(item)
            if take then
                item_name = reaper.GetTakeName(take)
            end
        end
        
        -- Extract champion/skin from name format: Viktor_Skin04
        local path_suffix = ""
        if item_name ~= "" then
            local champion, skin = item_name:match("^(.-)_(skin%d+)")
            if champion and skin then
                -- Capitalize the first letter of the champion name
                champion = champion:gsub("^%l", string.upper)  -- Capitalize first letter
                -- Ensure skin is in "SkinXX" format (capital "S" and two digits)
                skin = skin:gsub("^%l", string.upper)  -- Capitalize first letter of skin
                skin = skin:gsub("(%d+)$", function(digits)  -- Ensure two digits
                    return string.format("%02d", tonumber(digits))
                end)
                path_suffix = champion.."/"..champion.."_"..skin
            end
        end

        local render_path = base_path..path_suffix

        --- Set render settings ---------
        -- reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 5, true) 
        reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 8, true) -- use render region matrix
        reaper.GetSetProjectInfo(0, "RENDER_SRATE", 44100, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$region", true) -- setting region 
        reaper.GetSetProjectInfo_String(0, "RENDER_FILE", render_path, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "wav:24", true)
        reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 1, true) -- 1 = stereo\
        reaper.GetSetProjectInfo(0, "RENDER_RESAMPLE", 7, true) --- r8brain resample mode 

    end
end


function CreateSubprojectsWithRegions()-- create subprojects with regions 
    local track_count = reaper.CountTracks(0)

    -- Deselect all tracks first
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

    -- Select all tracks
    for i = 1, track_count - 1 do

        local track = reaper.GetTrack(0, i)
        reaper.Main_OnCommand(40289, 0) -- Unselect all media items

        reaper.SetTrackSelected(track, true)
        reaper.Main_OnCommand(41997, 0) -- create subproject
        reaper.Main_OnCommand(40297, 0) -- deselect all tracks
    end


    function count_project_tabs()
        local count = 0
        while reaper.EnumProjects(count, "") do
            count = count + 1
        end
        return count
    end


    local base_path = "T:/p4/depot/lol/_AUDIODEV_/Wwise/Originals/SFX/Champions/"

    local project_tab_count = count_project_tabs()

    for i = 1, project_tab_count -1 do --- it is for i=1 because we don't want to create regions in main proj
        --- Create subprojects 
        reaper.Main_OnCommand(40861,0) --- go to next project tab
        reaper.SelectAllMediaItems(0, true)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_REGIONSFROMITEMS"), 0) 
        reaper.Main_OnCommand(41890, 0) ---- render master mix for all regions


        -- Get first item name for path components
        local item_name = ""
        local item = reaper.GetSelectedMediaItem(0, 0)
        if item then
            local take = reaper.GetActiveTake(item)
            if take then
                item_name = reaper.GetTakeName(take)
            end
        end
        
        -- Extract champion/skin from name format: Viktor_Skin04
        local path_suffix = ""
        if item_name ~= "" then
            local champion, skin = item_name:match("^(.-)_(skin%d+)")
            if champion and skin then
                -- Capitalize the first letter of the champion name
                champion = champion:gsub("^%l", string.upper)  -- Capitalize first letter
                -- Ensure skin is in "SkinXX" format (capital "S" and two digits)
                skin = skin:gsub("^%l", string.upper)  -- Capitalize first letter of skin
                skin = skin:gsub("(%d+)$", function(digits)  -- Ensure two digits
                    return string.format("%02d", tonumber(digits))
                end)
                path_suffix = champion.."/"..champion.."_"..skin
            end
        end

        local render_path = base_path..path_suffix

        --- Set render settings ---------
        -- reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 5, true) 
        reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 8, true) -- use render region matrix
        reaper.GetSetProjectInfo(0, "RENDER_SRATE", 44100, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$region", true) -- setting region 
        reaper.GetSetProjectInfo_String(0, "RENDER_FILE", render_path, true)
        reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "wav:24", true)
        reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 1, true) -- 1 = stereo\
        reaper.GetSetProjectInfo(0, "RENDER_RESAMPLE", 7, true) --- r8brain resample mode 

    end
end

