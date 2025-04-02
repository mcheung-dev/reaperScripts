-- @author mcheung
-- @version 1.0 
-- Function to create region from selected items
local proj = 0 
local num_items = reaper.CountSelectedMediaItems(proj)
if num_items == 0 then
    reaper.ShowConsoleMsg("No items selected!\n")
    return
end

local min_pos = math.huge
local max_pos = 0
local region_name = nil  

for i = 0, num_items - 1 do
    local item = reaper.GetSelectedMediaItem(proj, i)
    if item then
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end = item_pos + item_len

        if item_pos < min_pos then min_pos = item_pos end
        if item_end > max_pos then max_pos = item_end end

        if region_name == nil then
            local take = reaper.GetActiveTake(item)
            if take then
                local retval, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                if retval and item_name ~= "" then
                    region_name = item_name
                end
            end
        end
    end
end

if not region_name then region_name = "Selected Items" end

local is_region = true
local region_index = reaper.AddProjectMarker2(proj, is_region, min_pos, max_pos, region_name, -1, 0)