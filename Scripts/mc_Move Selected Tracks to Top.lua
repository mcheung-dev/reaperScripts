-- @author mcheung
-- @version 1.0
function main()
    local num_selected_tracks = reaper.CountSelectedTracks(0)
    
    -- Check if there are any selected tracks
    if num_selected_tracks == 0 then
        reaper.ShowMessageBox("No tracks selected. Please select a track to move.", "Warning", 0)
        return
    end
    
    -- Loop through each selected track and move them to the top
    for i = num_selected_tracks - 1, 0, -1 do
        local track = reaper.GetSelectedTrack(0, i)
        reaper.ReorderSelectedTracks(0, 0) -- Move selected track(s) to the top
    end
end

-- Run the script
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Move selected track(s) to the top", -1)