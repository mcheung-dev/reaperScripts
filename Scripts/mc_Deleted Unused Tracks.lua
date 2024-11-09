-- @author mcheung
-- @version 1.0
function isTrackUnused(track)
    -- Check if the track has no media items
    if reaper.CountTrackMediaItems(track) > 0 then return false end

    -- Check if the track has any sends, receives, or hardware outputs
    if reaper.GetTrackNumSends(track, -1) > 0 then return false end -- Sends
    if reaper.GetTrackNumSends(track, 0) > 0 then return false end  -- Receives
    if reaper.GetTrackNumSends(track, 1) > 0 then return false end  -- Hardware outputs

    -- Check if the track has FX plugins
    if reaper.TrackFX_GetCount(track) > 0 then return false end

    -- Check if the track is record-armed
    if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 1 then return false end

    -- Check if the track has any envelopes
    if reaper.CountTrackEnvelopes(track) > 0 then return false end

    -- If none of the above conditions are met, the track is considered unused
    return true
end

function main()
    local num_tracks = reaper.CountTracks(0)
    
    -- Loop through all tracks from last to first to safely remove them
    for i = num_tracks - 1, 0, -1 do
        local track = reaper.GetTrack(0, i)
        
        -- Check if the track is unused
        if isTrackUnused(track) then
            reaper.SetTrackSelected(track, true) -- Select the track for deletion
        end
    end

    -- Delete selected tracks
    reaper.Main_OnCommand(40005, 0) -- Remove selected tracks
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
end

-- Run the script
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Remove unused tracks", -1)