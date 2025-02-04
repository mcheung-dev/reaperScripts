-- @author mcheung
-- @version 1.0 
-- Script that paste renders below original track

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40421, 0) -- select all itmes in track 

reaper.Main_OnCommand(40290, 0) -- Set time selection to items

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART"), 0)

-- Get the selected track
local sel_track = reaper.GetSelectedTrack(0, 0)
if sel_track then
    -- Get the index of the selected track
    local track_idx = reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER")
    
        -- Move the new track one slot below the original
        reaper.SetOnlyTrackSelected(sel_track)
        reaper.ReorderSelectedTracks(track_idx + 1, 0)
    end

reaper.Undo_EndBlock("Copy and paste track below", -1)

