-- @noindex

function InsertBefore(pattern_to_insert, insert_location)
    reaper.Undo_BeginBlock()
    if not pattern_to_insert or pattern_to_insert == "" then
        reaper.ShowMessageBox("Pattern cannot be empty", "Error", 0)
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
                    -- Perform case-insensitive pattern replacement
                    local pattern_lower = insert_location:lower()
                    local name_lower = current_name:lower()
                    local match_start, match_end = name_lower:find(pattern_lower, 1, true)

                    if match_start then
                        -- Insert before the matched text (preserve original case)
                        local matched_text = current_name:sub(match_start, match_end)
                        local new_name = current_name:sub(1, match_start - 1) .. pattern_to_insert .. matched_text .. current_name:sub(match_end + 1)

                        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
                        renamed_count = renamed_count + 1
                        reaper.UpdateItemInProject(item)
                    end
                end
            end
        end
    end

    if renamed_count > 0 then 
        local msg = string.format("Inserted pattern %s in %d items", pattern_to_insert, renamed_count)
        reaper.ShowMessageBox(msg, "Results", 0)
    else 
        reaper.ShowMessageBox("Original Pattern not found in selected items", 'error', 0)
    end
    
    -- Cleanup
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("undo", -1)
    return true
end

function InsertAfter(pattern_to_insert, insert_location)

    reaper.Undo_BeginBlock()

    if not pattern_to_insert or pattern_to_insert == "" then
        reaper.ShowMessageBox("Pattern cannot be empty", "Error", 0)
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
                    -- Perform case-insensitive pattern replacement
                    local pattern_lower = insert_location:lower()
                    local name_lower = current_name:lower()
                    local match_start, match_end = name_lower:find(pattern_lower, 1, true)

                    if match_start then
                        -- Insert after the matched text (preserve original case)
                        local matched_text = current_name:sub(match_start, match_end)
                        local new_name = current_name:sub(1, match_start - 1) .. matched_text .. pattern_to_insert .. current_name:sub(match_end + 1)

                        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
                        renamed_count = renamed_count + 1
                        reaper.UpdateItemInProject(item)
                    end
                end
            end
        end
    end

    if renamed_count > 0 then 
        local msg = string.format("Inserted pattern %s in %d items", pattern_to_insert, renamed_count)
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

function InsertAtPosition(pattern_to_insert, position)
    reaper.Undo_BeginBlock()

    if not pattern_to_insert or pattern_to_insert == "" then
        reaper.ShowMessageBox("Pattern cannot be empty", "Error", 0)
        return false
    end

    if not position then
        position = 0
    end

    -- Ensure position is non-negative
    if position < 0 then
        position = 0
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
                    local name_length = #current_name
                    local insert_pos = position

                    -- Clamp position to valid range (0 to length of string)
                    if insert_pos > name_length then
                        insert_pos = name_length
                    end

                    -- Insert at position: split string and insert pattern
                    local new_name = current_name:sub(1, insert_pos) .. pattern_to_insert .. current_name:sub(insert_pos + 1)

                    -- Update the name
                    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
                    renamed_count = renamed_count + 1
                    reaper.UpdateItemInProject(item)
                end
            end
        end
    end

    if renamed_count > 0 then
        local msg = string.format("Inserted pattern '%s' at position %d in %d items", pattern_to_insert, position, renamed_count)
        reaper.ShowMessageBox(msg, "Results", 0)
    else
        reaper.ShowMessageBox("No items were renamed", 'error', 0)
    end

    -- Cleanup
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Insert at position", -1)
    return true
end