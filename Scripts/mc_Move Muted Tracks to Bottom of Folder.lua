-- Reaper Lua Script: Move muted tracks to the bottom of their respective folders

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local track_count = reaper.CountTracks(0)
local folder_map = {}

-- Identify parent folders and their children
for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    if track then
        local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        local parent = reaper.GetParentTrack(track)
        
        -- Store tracks under their respective parents
        if parent then
            if not folder_map[parent] then
                folder_map[parent] = {tracks = {}, muted_tracks = {}}
            end
            -- Separate muted and unmuted tracks
            if reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
                table.insert(folder_map[parent].muted_tracks, track)
            else
                table.insert(folder_map[parent].tracks, track)
            end
        end
    end
end

-- Move muted tracks to the bottom of their respective folders
for parent, group in pairs(folder_map) do
    local insert_pos = reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER") -- Get parent track index
    
    -- Reinsert tracks: First unmuted, then muted
    for _, track in ipairs(group.tracks) do
        reaper.SetOnlyTrackSelected(track)
        reaper.ReorderSelectedTracks(insert_pos, 0)
        insert_pos = insert_pos + 1
    end
    for _, track in ipairs(group.muted_tracks) do
        reaper.SetOnlyTrackSelected(track)
        reaper.ReorderSelectedTracks(insert_pos, 0)
        insert_pos = insert_pos + 1
    end
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Move Muted Tracks to Bottom of Folders", -1)
reaper.UpdateArrange()