-- @author mcheung
-- @version 1.0
-- Script Name: Resolve Duplicate Region Names
-- Description: Finds regions with duplicate names and increments by number
-- Get the total number of markers and regions
local _, num_markers, num_regions = reaper.CountProjectMarkers(0)

-- Ensure there are regions to process
if num_regions == 0 then
    reaper.ShowMessageBox("No regions found!", "Error", 0)
    return
end

-- Function to generate a unique name by appending/incrementing a number
local function generate_unique_name(existing_names, base_name)
    local name = base_name
    local counter = 1

    while existing_names[name] do
        name = base_name .. "_0" .. counter .. ""
        counter = counter + 1
    end

    return name
end

-- Main script logic
reaper.Undo_BeginBlock() -- Begin undo block

local region_names = {}
local rename_map = {}

-- Collect all regions and their names
for i = 0, num_markers + num_regions - 1 do
    local retval, is_region, pos, end_pos, name, region_index = reaper.EnumProjectMarkers(i)
    if retval and is_region then
        if region_names[name] then
            -- Mark duplicate name for renaming
            rename_map[region_index] = {pos, end_pos, name}
        else
            -- Store unique names
            region_names[name] = true
        end
    end
end

-- Rename duplicates
for region_index, region_data in pairs(rename_map) do
    local pos, end_pos, duplicate_name = table.unpack(region_data)
    local new_name = generate_unique_name(region_names, duplicate_name)
    region_names[new_name] = true -- Add new name to the unique names set
    reaper.SetProjectMarker(region_index, true, pos, end_pos, new_name) -- Update region name
end

reaper.Undo_EndBlock("Resolve Duplicate Region Names", -1) -- End undo block

reaper.UpdateArrange() -- Refresh arrange view