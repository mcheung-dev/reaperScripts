-- @noindex

function Replace(original_pattern, new_pattern)
    reaper.Undo_BeginBlock()
    if not original_pattern or original_pattern == "" then
        reaper.ShowMessageBox("Original pattern cannot be empty", "Error", 0)
        return false
    end
    

    local proj = 0
    local renamed_count = 0
    local total_selected = reaper.CountSelectedMediaItems(proj)
    
    if total_selected == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return false
    end

    reaper.PreventUIRefresh(1)
    
    for i = 0, total_selected - 1 do
        local item = reaper.GetSelectedMediaItem(proj, i)
        if item then
            local take = reaper.GetActiveTake(item)
            if take then
                -- Get current name
                local retval, current_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                
                if retval and current_name ~= "" then
                    -- Perform pattern replacement
                    local new_name = current_name:gsub(original_pattern, new_pattern)
                    
                    -- Only update if name changed
                    if new_name ~= current_name then
                        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
                        renamed_count = renamed_count + 1
                        reaper.UpdateItemInProject(item)
                    end
                end
            end
        end
    end

    if renamed_count > 0 then 
        local msg = string.format("Renamed %d items\nPattern: %s → %s", renamed_count, original_pattern, new_pattern)
        reaper.ShowMessageBox(msg, "Results", 0)
    else 
        reaper.ShowMessageBox("Original Pattern not found in selected items", 'error', 0)
    end
    
    -- Cleanup
    reaper.Undo_EndBlock("undo", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    return true
end