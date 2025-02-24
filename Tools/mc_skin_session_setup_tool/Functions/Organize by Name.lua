-- @noindex

-- Function to check if a track with a given name exists
function OrganizeByName()
    function createtracks()-- Create tracks if they don't already exist

        local track = reaper.GetSelectedTrack(0, 0) -- Get the first selected track
        if track then
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Uncategorized", true)
        end

        local track_names = {"P", "AA", "Q", "W", "E", "R", "Emotes"}
        for _, name in ipairs(track_names) do
            local new_track = reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
            local track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
        end
        reaper.TrackList_AdjustWindows(false)
        reaper.UpdateArrange()
    end



    function main()
        reaper.Undo_BeginBlock()
        reaper.PreventUIRefresh(1)

        
        -- Store selected items
        local items = {}
        local count = reaper.CountSelectedMediaItems(0)
        for i = 0, count-1 do
            items[i+1] = reaper.GetSelectedMediaItem(0, i)
        end

        -- Move items to correct tracks
        for _, item in ipairs(items) do
            local take = reaper.GetActiveTake(item)
            if take then
                local name = reaper.GetTakeName(take):lower()
                local target_track = nil
                
                -- Track assignment logic
                if name:find("_basicattack%d*_") or name:find("_critattack") then
                    target_track = find_track_by_name("AA")
                elseif name:find("_emote_") then
                    target_track = find_track_by_name("Emotes")
                else
                    local _, _, letter = name:find("_([a-z])_")
                    if letter then
                        target_track = find_track_by_name(letter:upper())
                    end
                end
                
                if target_track then
                    reaper.MoveMediaItemToTrack(item, target_track)
                end
            end
        end

        -- Group and position items
        local track_groups = {}
        
        -- Process items per track with intelligent sorting
        for _, track in ipairs(get_all_tracks()) do
            local track_items = {}
            -- Collect items on this track in selection order
            for _, item in ipairs(items) do
                if reaper.GetMediaItem_Track(item) == track then
                    table.insert(track_items, item)
                end
            end
            
            if #track_items > 0 then
                -- Group and sort variations
                local groups = {}
                local group_order = {}
                
                for _, item in ipairs(track_items) do
                    local take = reaper.GetActiveTake(item)
                    if take then
                        local name = reaper.GetTakeName(take)
                        local base, num = parse_name(name)
                        
                        if not groups[base] then
                            groups[base] = {}
                            table.insert(group_order, base)
                        end
                        table.insert(groups[base], {item=item, num=num})
                    end
                end
                
                -- Sort each group numerically
                for _, group in pairs(groups) do
                    table.sort(group, function(a, b) return a.num < b.num end)
                end
                
                -- Position items sequentially
                local start_pos = 0.0
                for _, base in ipairs(group_order) do
                    for _, entry in ipairs(groups[base]) do
                        local item = entry.item
                        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                        reaper.SetMediaItemInfo_Value(item, "D_POSITION", start_pos)
                        start_pos = start_pos + length + 0.5
                    end
                end
            end
        end

        reaper.SetEditCurPos(0, true, false) --- set cursor to the start 

        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("Smart Item Organization", -1)
    end

    function parse_name(name)
        -- Remove file extension and lowercase
        local base = name:gsub("%..+$", ""):lower()
        
        -- Match patterns like "_01" or "-02" at the end
        local base_part, num_str = base:match("^(.-)[_-](%d+)$")
        
        -- If no match, check for trailing numbers without separator
        if not base_part then
            base_part, num_str = base:match("^(.-)(%d+)$")
        end
        
        return base_part or base, tonumber(num_str) or 0
    end

    function find_track_by_name(name)
        local lower_target = name:lower()
        for t = 0, reaper.CountTracks(0)-1 do
            local track = reaper.GetTrack(0, t)
            local _, track_name = reaper.GetTrackName(track, "")
            if track_name:lower() == lower_target then
                return track
            end
        end
        return nil
    end

    function get_all_tracks()
        local tracks = {}
        for t = 0, reaper.CountTracks(0)-1 do
            table.insert(tracks, reaper.GetTrack(0, t))
        end
        return tracks
    end
    createtracks() --------- running the function when it is called
    main()
end

function DeleteAllTracks()
    for i = reaper.CountTracks(0) - 1, 0, -1 do
        local track = reaper.GetTrack(0, i)
        reaper.DeleteTrack(track)
    end
end