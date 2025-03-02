package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require('Functions/Randomize Function')

function Gettoptrack()
    -- Initialize variables
    local topmostTrack = nil
    local topmostTrackIndex = math.huge  -- Start with a very high index

    -- Get the number of selected media items
    local numItems = reaper.CountSelectedMediaItems(0)

    if numItems > 0 then
        for i = 0, numItems - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)  -- Get item
            local track = reaper.GetMediaItemTrack(item)  -- Get item's track
            local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") -- Get track index

            -- Check if this track is higher in the track list
            if trackIndex < topmostTrackIndex then
                topmostTrack = track
                topmostTrackIndex = trackIndex
            end
        end

        -- Select the topmost track
        if topmostTrack then
            reaper.SetOnlyTrackSelected(topmostTrack) -- Select only the topmost track
        end
    end
end

function copy_selected_items()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowConsoleMsg("No items selected.\n")
        return
    end

    -- Store original selected items
    local original_items = {}
    local last_item_end = 0

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            table.insert(original_items, item)
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- Function to check for the next overlapping region and adjust paste position
    local function find_safe_paste_position(start_pos, offset)
        local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
        local safe_paste_pos = start_pos + offset

        for i = 0, num_markers + num_regions - 1 do
            local _, is_region, region_start, _, _, _ = reaper.EnumProjectMarkers(i)
            if is_region and region_start > start_pos and region_start < safe_paste_pos then
                safe_paste_pos = region_start - 0.01  -- Move it just before the region
                break
            end
        end

        return safe_paste_pos
    end

    -- Determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    -- Begin undo block
    reaper.Undo_BeginBlock()

    -- Copy using Reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- Move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    -- Toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- Paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- Toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- -- Reselect original items
    -- reaper.Main_OnCommand(40289, 0) -- Unselect all items
    -- for _, item in ipairs(original_items) do
    --     reaper.SetMediaItemSelected(item, true)
    -- end

    -- Update UI
    reaper.UpdateArrange()

    -- End undo block
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end


function copy_selected_items_randomize()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowConsoleMsg("No items selected.\n")
        return
    end

    -- Store original selected items
    local original_items = {}
    local last_item_end = 0

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            table.insert(original_items, item)
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- Function to check for the next overlapping region and adjust paste position
    local function find_safe_paste_position(start_pos, offset)
        local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
        local safe_paste_pos = start_pos + offset

        for i = 0, num_markers + num_regions - 1 do
            local _, is_region, region_start, _, _, _ = reaper.EnumProjectMarkers(i)
            if is_region and region_start > start_pos and region_start < safe_paste_pos then
                safe_paste_pos = region_start - 0.01  -- Move it just before the region
                break
            end
        end

        return safe_paste_pos
    end

    -- Determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    -- Begin undo block
    reaper.Undo_BeginBlock()

    -- Copy using Reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- Move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    -- Toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- Paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- Toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 
    
    RandomizeSelectedItems()

    -- Reselect original items
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    for _, item in ipairs(original_items) do
        reaper.SetMediaItemSelected(item, true)
    end

    -- Update UI
    reaper.UpdateArrange()

    -- End undo block
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end

function copy_selected_items_randomize_regions()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowConsoleMsg("No items selected.\n")
        return
    end

    -- Store original selected items
    local original_items = {}
    local last_item_end = 0

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            table.insert(original_items, item)
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- Function to check for the next overlapping region and adjust paste position
    local function find_safe_paste_position(start_pos, offset)
        local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
        local safe_paste_pos = start_pos + offset

        for i = 0, num_markers + num_regions - 1 do
            local _, is_region, region_start, _, _, _ = reaper.EnumProjectMarkers(i)
            if is_region and region_start > start_pos and region_start < safe_paste_pos then
                safe_paste_pos = region_start - 0.01  -- Move it just before the region
                break
            end
        end

        return safe_paste_pos
    end

    -- Determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    -- Begin undo block
    reaper.Undo_BeginBlock()

    -- Copy using Reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- Move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    -- Toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- Paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- Toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 
    
    RandomizeSelectedItems()

    CreateIncrementedRegion()

    -- Reselect original items
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    for _, item in ipairs(original_items) do
        reaper.SetMediaItemSelected(item, true)
    end

    -- Update UI
    reaper.UpdateArrange()

    -- End undo block
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end