-- @author mcheung
-- @version 1.0 
-- Move all muted tracks to the bottom of the session, except tracks named "VIDEO" and "REFERENCE"
function main()
    local num_tracks = reaper.CountTracks(0)
    local muted_tracks = {}

    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local is_muted = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1

        local _, track_name = reaper.GetTrackName(track)
        local track_name_lower = string.lower(track_name)
        
        if is_muted and track_name_lower ~= "video" and track_name_lower ~= "reference" then
            table.insert(muted_tracks, track)
        end
    end


    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

    -- Move each muted track to the bottom
    for _, track in ipairs(muted_tracks) do
        reaper.SetOnlyTrackSelected(track) -- Select only this muted track
        reaper.ReorderSelectedTracks(num_tracks, 0) 
        reaper.SetTrackSelected(track, false) 
    end
end

-- Run the script
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Move muted tracks to bottom", -1)
reaper.UpdateArrange()
