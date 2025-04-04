-- @author mcheung
-- @version 1.0
-- script that sets all tracks to 0dB
function main()
    local num_tracks = reaper.CountTracks(0)
    
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1.0) -- 1.0 represents 0 dB in Reaper
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Set all track volumes to 0 dB", -1)

