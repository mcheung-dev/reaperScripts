function implode_takes()
-- helper: wait N seconds then call cb()
    local function wait(seconds, cb)
        local start = reaper.time_precise()
        local function poll()
        if reaper.time_precise() - start >= seconds then
            cb()
        else
            reaper.defer(poll)
        end
        end
        reaper.defer(poll)
    end
    
    -- MAIN ---------------------
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local items = {}
    local item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take then
            -- Store item info for later
            local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local original_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local original_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            
            -- Store fade information
            local fadein = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
            local fadeout = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
            local fadein_curve = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR")
            local fadeout_curve = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
            local fadein_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
            local fadeout_shape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
            
            -- Get media source correctly
            local source = reaper.GetMediaItemTake_Source(take)
            local source_length, lengthIsQN = reaper.GetMediaSourceLength(source)
            
            -- Reset item to full source length and zero offset
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", source_length)
            reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", 0)
            
            table.insert(items, {
                item = item,
                position = position,
                original_length = original_length,
                original_offset = original_offset,
                fadein = fadein,
                fadeout = fadeout,
                fadein_curve = fadein_curve,
                fadeout_curve = fadeout_curve,
                fadein_shape = fadein_shape,
                fadeout_shape = fadeout_shape
            })
        end
    end

    -- 1) split default settings
    local defaults = {
        threshold = "-36",   -- in dB
        padleft   = "0.005", -- seconds before each hit
        padright  = "0.005", -- seconds after each hit
        fadein    = "0.005", -- fade-in length
        fadeout   = "0.005", -- fade-out length
        minlen    = "0.05",  -- minimum slice length
        detectsilence = "0", -- 0 = detect peaks, 1 = detect silence
    }
      -- 2) write them into the dynamic_split ExtState
    for key, val in pairs(defaults) do
        -- section "dynamic_split" is what REAPER uses internally
        reaper.SetExtState("dynamic_split", key, val, true)
    end
    
    -- Store initial state for comparison
    local initial_total_item_count = reaper.CountMediaItems(0)
    local initial_selection_count = reaper.CountSelectedMediaItems(0)
    
    -- Store GUIDs of original items for reliable tracking
    local original_item_guids = {}
    for i = 0, initial_selection_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(original_item_guids, reaper.BR_GetMediaItemGUID(item))
    end
    
    -- 3) dynamic split using last settings
    reaper.Main_OnCommand(42951, 0)
    reaper.UpdateArrange()
    
    --polls to check if dynamic split has completed
    local function checkDynamicSplitComplete()
        local maxWaitTime = 20 
        local pollInterval = 0.25 
        local startTime = reaper.time_precise()
        
        local function pollForCompletion()
            if reaper.time_precise() - startTime > maxWaitTime then
                reaper.Main_OnCommand(40543, 0)
                reaper.UpdateArrange()
                return
            end
            
            local new_total_item_count = reaper.CountMediaItems(0)
            local new_selection_count = reaper.CountSelectedMediaItems(0)
            

            local items_created = new_total_item_count > initial_total_item_count
            local selection_changed = new_selection_count > initial_selection_count
            

            local original_items_modified = false
            for _, guid in ipairs(original_item_guids) do
                local item = reaper.BR_GetMediaItemByGUID(0, guid)
                if item and not reaper.IsMediaItemSelected(item) then
                    original_items_modified = true
                    break
                end
            end
            

            local split_succeeded = items_created or selection_changed or original_items_modified
            
            if split_succeeded then

                reaper.Main_OnCommand(40543, 0)
                reaper.UpdateArrange()
                
                local new_item_count = reaper.CountSelectedMediaItems(0)
                   
                for i = 0, math.min(new_item_count-1, #items-1) do
                    local new_item = reaper.GetSelectedMediaItem(0, i)
                    local original_data = items[i+1]
                    
                    if new_item and original_data then
                       
                        reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", original_data.position)
                        reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", original_data.original_length)
                      
                        local active_take = reaper.GetActiveTake(new_item)
                        if active_take then
                            reaper.SetMediaItemTakeInfo_Value(active_take, "D_STARTOFFS", original_data.original_offset)
                        end
                        
                        reaper.SetMediaItemInfo_Value(new_item, "D_FADEINLEN", original_data.fadein)
                        reaper.SetMediaItemInfo_Value(new_item, "D_FADEOUTLEN", original_data.fadeout)
                        reaper.SetMediaItemInfo_Value(new_item, "D_FADEINDIR", original_data.fadein_curve)
                        reaper.SetMediaItemInfo_Value(new_item, "D_FADEOUTDIR", original_data.fadeout_curve)
                        reaper.SetMediaItemInfo_Value(new_item, "C_FADEINSHAPE", original_data.fadein_shape)
                        reaper.SetMediaItemInfo_Value(new_item, "C_FADEOUTSHAPE", original_data.fadeout_shape)
                    end
                end
            else
                reaper.defer(pollForCompletion)
            end
        end
        
        reaper.defer(pollForCompletion)
    end
    
    checkDynamicSplitComplete()

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Dynamic split & implode takes", -1)
end