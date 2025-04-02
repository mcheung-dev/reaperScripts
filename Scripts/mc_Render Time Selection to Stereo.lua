-- @author mcheung
-- @version 1.0 
-- Script that paste renders below original track

reaper.Undo_BeginBlock()

reaper.Main_OnCommand(40421, 0) -- select all itmes in track 

reaper.Main_OnCommand(40290, 0) -- Set time selection to items

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART"), 0)


local sel_track = reaper.GetSelectedTrack(0, 0)
if sel_track then

    local track_idx = reaper.GetMediaTrackInfo_Value(sel_track, "IP_TRACKNUMBER")
    

        reaper.SetOnlyTrackSelected(sel_track)
        reaper.ReorderSelectedTracks(track_idx + 1, 0)
    end
    
reaper.Main_OnCommand(40635, 0) -- remove time selection 

reaper.Undo_EndBlock("Copy and paste track below", -1)

