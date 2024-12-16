-- @author mcheung
-- @version 1.0 
-- Move all muted tracks to the bottom of the session, except tracks named "VIDEO" and "REFERENCE"
function main()
    local num_tracks = reaper.CountTracks(0)
    local muted_tracks = {}

    -- Gather only muted tracks, excluding "VIDEO" and "REFERENCE"
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local is_muted = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1

        -- Add to list only if the track is muted and not named "VIDEO" or "REFERENCE"
        if is_muted and track_name ~= "VIDEO" and track_name ~= "REFERENCE" and track_name ~= "video" and track_name ~= "reference" then
            table.insert(muted_tracks, track)
        end
    end

    -- Deselect all tracks initially to avoid any interference
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks

    -- Move each muted track to the bottom
    for _, track in ipairs(muted_tracks) do
        reaper.SetOnlyTrackSelected(track) -- Select only this muted track
        reaper.ReorderSelectedTracks(num_tracks, 0) -- Move the selected track to the bottom
        reaper.SetTrackSelected(track, false) -- Deselect after moving to prevent interference
    end
end

-- Run the script
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Move muted tracks to bottom", -1)
reaper.UpdateArrange()
