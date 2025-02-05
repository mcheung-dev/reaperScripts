-- @author mcheung
-- @version 1.0 
-- Function to rename duplicate regions
function rename_duplicate_regions()
    -- Get the number of regions
    local num_regions = reaper.CountProjectMarkers(0)
    
    if num_regions == 0 then
        reaper.ShowMessageBox("No regions found in the project!", "Error", 0)
        return
    end
    
    -- Create a table to store base names and their counts
    local name_counts = {}
    
    -- Loop through all regions
    for i = 0, num_regions - 1 do
        local retval, is_region, pos, rgn_end, name, index = reaper.EnumProjectMarkers(i)
        
        if is_region then
            -- Check if the region name ends with _01, _02, etc.
            local base_name, suffix = name:match("^(.*)_(%d+)$")
            
            if base_name and suffix then
                -- If the base name already exists in the table, increment the count
                if name_counts[base_name] then
                    name_counts[base_name] = name_counts[base_name] + 1
                else
                    name_counts[base_name] = tonumber(suffix)
                end
                
                -- Create the new name
                local new_name = base_name .. "_" .. string.format("%02d", name_counts[base_name])
                
                -- Update the region name
                reaper.SetProjectMarker(index, true, pos, rgn_end, new_name)
            else
                -- If the name doesn't match the pattern, skip it
                reaper.ShowConsoleMsg("Skipping region: " .. name .. " (does not match _01 pattern)\n")
            end
        end
    end
    
    reaper.UpdateArrange()
    reaper.ShowMessageBox("Region renaming complete!","Success!", 0)
end

-- Run the function
rename_duplicate_regions()