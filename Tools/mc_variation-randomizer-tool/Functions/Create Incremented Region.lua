-- global variable to store last selected region name
lastSelectedRegionName = nil

-- function to track last selected region based on time selection
function DetectLastSelectedRegion()
    local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)    -- if no valid time selection, do nothing
    if start_time == end_time then return end
    
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)

    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, region_start, region_end, region_name, _ = reaper.EnumProjectMarkers(i)

        -- if time selection matches a region, store it as the last selected region
        if is_region and math.abs(region_start - start_time) < 0.001 and math.abs(region_end - end_time) < 0.001 then
            lastSelectedRegionName = region_name
            return
        end
    end
end

-- function to retrieve the last selected region name
function GetLastSelectedRegion()
    DetectLastSelectedRegion()  -- update last selected region if applicable
    return lastSelectedRegionName or "Region"  -- default if no region was selected
end

-- function to update the base region name dynamically
function UpdateBaseRegionName()
    -- default base name (used when no region has been selected)
    local baseRegionName = "Region"

    -- get the last region name if available
    local lastRegionName = GetLastSelectedRegion()

    -- if we have a last region name
    if lastRegionName then
        -- extract base name by removing numeric suffix (_01, _02, etc.)
        baseRegionName = lastRegionName:match("^(.-)_%d+$") or lastRegionName
    end

    -- default to "Region" if no previous name is found
    if not baseRegionName or baseRegionName == "" then
        baseRegionName = "Region"
    end
    
    return baseRegionName
end

-- function to find the next available suffix for a region name
function FindNextAvailableSuffix(baseName)
    -- find the highest suffix (_01, _02, etc.) currently in use
    local maxSuffix = 0
    local retval, numMarkers, numRegions = reaper.CountProjectMarkers(0)
    
    -- pattern to match base name followed by _XX where XX is a number
    local pattern = "^" .. baseName:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1") .. "_(%d+)$"
    
    for i = 0, numMarkers + numRegions - 1 do
        local _, isRegion, _, _, name, _ = reaper.EnumProjectMarkers(i)
        if isRegion then
            -- Remove .wav or other extensions
            local cleanName = name:gsub("%.[^.]+$", "")
            
            -- Check if this region matches our base name pattern
            local suffixMatch = cleanName:match(pattern)
            if suffixMatch then
                local suffixNum = tonumber(suffixMatch)
                if suffixNum and suffixNum > maxSuffix then
                    maxSuffix = suffixNum
                end
            end
        end
    end
    
    -- Return the next available number
    return maxSuffix + 1
end

-- function to create an incremented region using the last selected region's name
function CreateIncrementedRegion()
    -- get the base region name
    local baseRegionName = UpdateBaseRegionName()    local numItems = reaper.CountSelectedMediaItems(0)

    local minStart = math.huge
    local maxEnd = 0

    -- determine region bounds from selected media items
    for i = 0, numItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd = itemStart + itemLength

        if itemStart < minStart then minStart = itemStart end
        if itemEnd > maxEnd then maxEnd = itemEnd end
    end    -- find the next available suffix for this base name
    local nextSuffix = FindNextAvailableSuffix(baseRegionName)
    
    -- format the new region name with padded zeros (e.g., _01, _02, etc.)
    local newRegionName = string.format("%s_%02d", baseRegionName, nextSuffix)

    -- adjust bounds slightly to prevent overlap
    local regionPadding = 0.01 -- small padding in seconds
    
    -- create the new region
    reaper.AddProjectMarker2(0, true, minStart - regionPadding, maxEnd + regionPadding, newRegionName, -1, 0)

    return newRegionName
end

-- function to get all region names in project
function GetAllRegionNames()
    local regions = {}
    local retval, num_markers, num_regions = reaper.CountProjectMarkers(0)
    
    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, _, _, name, _ = reaper.EnumProjectMarkers(i)
        if is_region then
            table.insert(regions, name)
        end
    end
    
    return regions
end
