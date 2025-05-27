--@noindex
package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require('Functions/Randomize Function')

function Gettoptrack()
    local topmostTrack = nil
    local topmostTrackIndex = math.huge  -- Start with a very high index
    
    local numItems = reaper.CountSelectedMediaItems(0)

    if numItems > 0 then
        for i = 0, numItems - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)  -- Get item
            local track = reaper.GetMediaItemTrack(item)  -- Get item's track
            local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") -- Get track index

            -- check if this track is higher in the track list
            if trackIndex < topmostTrackIndex then
                topmostTrack = track
                topmostTrackIndex = trackIndex
            end
        end

        if topmostTrack then
            reaper.SetOnlyTrackSelected(topmostTrack) -- Select only the topmost track
        end
    end
end

function copy_selected_items()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowMessageBox('Please select an item', 'Error', 0)
        return
    end

    local last_item_end = 0
    
    -- track selected items to compare with after paste
    local original_selected_guids = {}

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            -- store the guid for reliable item tracking
            table.insert(original_selected_guids, reaper.BR_GetMediaItemGUID(item))
            
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- function to check for the next overlapping region and adjust paste position
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

    -- determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    reaper.Undo_BeginBlock()

    -- copy using reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    reaper.Main_OnCommand(40635, 0)  -- Ripple all tracks: OFF

    -- toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- -- reselect original items
    -- reaper.main_oncommand(40289, 0) -- unselect all items
    -- for _, item in ipairs(original_items) do
    --     reaper.setmediaitemselected(item, true)
    -- end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end


function copy_selected_items_randomize()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowMessageBox('No items selected, please select items', 'Error', 0)
        return
    end

    -- store information about the current selection
    local last_item_end = 0
    
    -- track selected items to compare with after paste
    local original_selected_guids = {}

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            -- store the guid for reliable item tracking
            table.insert(original_selected_guids, reaper.BR_GetMediaItemGUID(item))
            
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- function to check for the next overlapping region and adjust paste position
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

    -- determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    reaper.Undo_BeginBlock()

    -- copy using reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    reaper.Main_OnCommand(40635, 0)  -- Ripple all tracks: OFF

    -- toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 
      RandomizeSelectedItems()

    -- keep the newly pasted items selected (which happens by default)
    -- don't reselect original items, so if the user runs this again, 
    -- it will work with the newly created items

    -- update ui
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end

function copy_selected_items_randomize_regions()
    local num_items = reaper.CountSelectedMediaItems(0)
    if num_items == 0 then
        reaper.ShowMessageBox('No items selected, please select items', 'Error', 0)
        return
    end

    -- store information about the current selection
    local last_item_end = 0
    
    -- track selected items to compare with after paste
    local original_selected_guids = {}

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            -- store the guid for reliable item tracking
            table.insert(original_selected_guids, reaper.BR_GetMediaItemGUID(item))
            
            local item_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") +
                             reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            last_item_end = math.max(last_item_end, item_end)
        end
    end

    -- function to check for the next overlapping region and adjust paste position
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

    -- determine paste position with a 0.5s offset unless it overlaps a region
    local offset_time = 0.5
    local paste_position = find_safe_paste_position(last_item_end, offset_time)

    reaper.Undo_BeginBlock()

    -- copy using reaper's built-in function
    reaper.Main_OnCommand(40057, 0) -- Copy selected items

    -- move cursor to paste position
    reaper.SetEditCurPos(paste_position, false, false)

    -- toggle ripple editing on (all tracks)
    reaper.Main_OnCommand(41991, 0) 

    -- paste items
    reaper.Main_OnCommand(40058, 0) -- Paste items

    -- toggle ripple editing off (all tracks)
    reaper.Main_OnCommand(41991, 0) 
    
    RandomizeSelectedItems()    CreateIncrementedRegion()

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Copy and Paste Selected Media Items (Adjusted for Regions)", -1)
end
