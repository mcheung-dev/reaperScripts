
-- @author mcheung
-- @version 1.0 


function TrackUnused(track)
    if reaper.CountTrackMediaItems(track) > 0 then return false end -- has media items
    if reaper.GetTrackNumSends(track, -1) > 0 then return false end -- has sends
    if reaper.GetTrackNumSends(track, 0) > 0 then return false end -- has receives
    if reaper.GetTrackNumSends(track, 1) > 0 then return false end -- has hardware output
    if reaper.TrackFX_GetCount(track) > 0 then return false end -- has FX plugins
    if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 1 then return false end -- is armed
    if reaper.CountTrackEnvelopes(track) > 0 then return false end -- has envelopes
    return true -- if all conditions are met, track is "unused"
end

function SaveSelectedTracks()
    local selected_tracks = {}
    for i = 0, reaper.CountSelectedTracks(0) - 1 do
        table.insert(selected_tracks, reaper.GetSelectedTrack(0, i))
    end
    return selected_tracks
end

function Main()
    tracks = SaveSelectedTracks()
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    local trackCount = reaper.GetNumTracks()
    for i = trackCount - 1, 0, -1 do
        local track = reaper.GetTrack(0, i)
        if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then -- is folder parent
            local childUsed
            local depth = reaper.GetTrackDepth(track)
            local trackidx = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
            local child = reaper.GetTrack(0, trackidx)
            if child then
                local childDepth = reaper.GetTrackDepth(child)
                while child and childDepth > depth and trackidx < trackCount do
                    if not reaper.IsTrackSelected(child) then
                        childUsed = true
                        break
                    end
                    child = reaper.GetTrack(0, trackidx)
                    childDepth = reaper.GetTrackDepth(child)
                    trackidx = trackidx + 1
                end
            end
            if not childUsed then reaper.SetTrackSelected(track, TrackUnused(track)) end
        else
            reaper.SetTrackSelected(track, TrackUnused(track))
        end
    end
    reaper.Main_OnCommand(40005, 0) -- remove selected tracks
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    for i, track in ipairs(tracks) do
        if reaper.ValidatePtr(track, 'MediaTrack*') then reaper.SetTrackSelected(track, true) end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("MC_Remove Unused Tracks", -1)
