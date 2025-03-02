-- Global variable to store last selected region name
lastSelectedRegionName = nil

-- Function to track last selected region based on time selection
function DetectLastSelectedRegion()
    local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    -- If no valid time selection, do nothing
    if start_time == end_time then return end

    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)

    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, region_start, region_end, region_name, _ = reaper.EnumProjectMarkers(i)

        -- If time selection matches a region, store it as the last selected region
        if is_region and math.abs(region_start - start_time) < 0.001 and math.abs(region_end - end_time) < 0.001 then
            lastSelectedRegionName = region_name
            return
        end
    end
end

-- Function to retrieve the last selected region name
function GetLastSelectedRegion()
    DetectLastSelectedRegion()  -- Update last selected region if applicable
    return lastSelectedRegionName or "Region"  -- Default if no region was selected
end

-- Function to update the base region name dynamically
function UpdateBaseRegionName()
    -- Get last selected region name
    local lastRegionName = GetLastSelectedRegion()

    if lastRegionName then
        -- Extract base name by removing numeric suffix (_01, _02, etc.)
        baseRegionName = lastRegionName:match("^(.-)_%d+$") or lastRegionName
    end

    -- Default to "Region" if no previous name is found
    if not baseRegionName or baseRegionName == "" then
        baseRegionName = "Region"
    end
end

-- Function to create an incremented region using the last selected region's name
function CreateIncrementedRegion()
    -- **Always update base region name before creating a new one**
    UpdateBaseRegionName()

    local num_items = reaper.CountSelectedMediaItems(0)

    local min_start = math.huge
    local max_end = 0

    -- Determine region bounds from selected media items
    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end = item_start + item_length

        if item_start < min_start then min_start = item_start end
        if item_end > max_end then max_end = item_end end
    end

    -- Check if the base name has a .wav extension
    local has_wav_extension = baseRegionName:match("%.wav$")
    local clean_base_name = baseRegionName:gsub("%.wav$", "") -- Remove .wav

    -- Extract base name and suffix (oc_01 → oc, _01)
    local name_without_suffix, existing_suffix = clean_base_name:match("^(.-)(_?%d+)$")

    -- If no valid suffix, assume the base name is fully the name
    if not existing_suffix then
        name_without_suffix = clean_base_name
        existing_suffix = "_00" -- Start from _00 so the next is _01
    end

    -- Find the highest suffix (_01, _02, etc.)
    local max_suffix = tonumber(existing_suffix:match("%d+")) or 0
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)

    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, _, _, name_check, _ = reaper.EnumProjectMarkers(i)

        -- Remove .wav for checking suffixes
        local clean_name = name_check:gsub("%.wav$", "")

        -- Match names in the format: `oc_01`, `oc_02`
        local match_name, match_suffix = clean_name:match("^(.-)(_?%d+)$")
        if match_name and match_name == name_without_suffix then
            local num = tonumber(match_suffix:match("%d+"))
            if num and num > max_suffix then
                max_suffix = num
            end
        end
    end

    -- Increment the suffix correctly
    local new_suffix = max_suffix + 1
    local new_region_name = name_without_suffix .. string.format("_%02d", new_suffix)

    -- Reattach .wav if the original region had it
    if has_wav_extension then
        new_region_name = new_region_name .. ".wav"
    end

    -- Create a new region with the incremented name
    reaper.AddProjectMarker2(0, true, min_start, max_end, new_region_name, -1, 0)

    reaper.Main_OnCommand(41890, 0) -- Add regions to render region matrix 

    reaper.Undo_EndBlock("Create New Incremented Region", -1)
    reaper.UpdateArrange()
end
