-- @noindex

function Remove(pattern_remove)
    reaper.Undo_BeginBlock()
    if not pattern_remove or pattern_remove == "" then
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
                    local new_name = current_name:gsub(pattern_remove, '')
                    
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
        local msg = string.format("Removed Pattern: %s in %d items", pattern_remove, renamed_count)
        reaper.ShowMessageBox(msg, "Results", 0)
    else 
        reaper.ShowMessageBox("Pattern not found in selected items", 'error', 0)
    end
    
    -- Cleanup
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("undo", -1)
    return true
end