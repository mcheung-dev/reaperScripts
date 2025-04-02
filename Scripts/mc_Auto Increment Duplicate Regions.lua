-- @author mcheung
-- @version 1.2
-- Function to rename duplicate regions, useful for render export regions
function rename_duplicate_regions()
    local num_regions = reaper.CountProjectMarkers(0)
    
    if num_regions == 0 then
        reaper.ShowMessageBox("No regions found in the project!", "Error", 0)
        return
    end
    
    local name_counts = {}
    
    for i = 0, num_regions - 1 do
        local retval, is_region, pos, rgn_end, name, index = reaper.EnumProjectMarkers(i)
        
        if is_region then
            -- remove .wav extension
            local name_clean = name:gsub("%.wav$", "")
            
            -- only process names that end with _01
            local base_name, suffix = name_clean:match("^(.*)_(%d+)$")
            
            if base_name and suffix then
                suffix = tonumber(suffix)
                if name_counts[base_name] then
                    name_counts[base_name] = name_counts[base_name] + 1
                else
                    name_counts[base_name] = suffix
                end
                
                local new_suffix = string.format("%02d", name_counts[base_name])
                local new_name = base_name .. "_" .. new_suffix
                
                reaper.SetProjectMarker(index, true, pos, rgn_end, new_name)
            end
        end
    end
    
    reaper.UpdateArrange()
end


rename_duplicate_regions()