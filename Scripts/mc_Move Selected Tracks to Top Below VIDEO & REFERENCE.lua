-- @author mcheung
-- @version 1.0

    local function get_target_index()
        local track_count = reaper.CountTracks(0)
        local target_index = 0 -- Default to top if VIDEO and REFERENCE are not found
    
        for i = 0, track_count - 1 do
            local track = reaper.GetTrack(0, i)
            local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            if track_name and (track_name:upper() == "VIDEO" or track_name:upper() == "REFERENCE") then
                target_index = i + 1
            end
        end
        return target_index
    end
    

    reaper.Undo_BeginBlock()
    
    local target_index = get_target_index()
    local selected_tracks = {}

    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if reaper.IsTrackSelected(track) then
            table.insert(selected_tracks, track)
        end
    end
    for _, track in ipairs(selected_tracks) do
        reaper.ReorderSelectedTracks(target_index, 0) -- Move to target_index
        target_index = target_index + 1
    end
    
    reaper.Undo_EndBlock("Move selected tracks below VIDEO and REFERENCE", -1)
    