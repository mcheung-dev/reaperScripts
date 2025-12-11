--@noindex
function RandomizeSelectedItems(proj)
    -- User settings
    local min_pos = Settings.pos.min -- in ms
    local max_pos = Settings.pos.max

    local min_pitch = Settings.pitch.min
    local max_pitch = Settings.pitch.max

    local min_rate = Settings.rate.min
    local max_rate = Settings.rate.max

    local min_vol = Settings.vol.min
    local max_vol = Settings.vol.max

    local min_cont = Settings.content.min
    local max_cont = Settings.content.max
    
    local randomize_takes = Settings.takes
    ---

    local lower_value = 0.0001
    if min_rate <= 0 then 
        min_rate = lower_value
    end

    ---- Code 
    local sel_items = {}
    local cnt = reaper.CountSelectedMediaItems(proj)

    if cnt == 0 then
        reaper.ShowMessageBox('no items selected', 'error' , 0)
        return
    end

    reaper.Undo_BeginBlock2(0)
    reaper.PreventUIRefresh(1)

    for i = 0, cnt - 1 do 
        local item = reaper.GetSelectedMediaItem(proj, i)
        table.insert(sel_items, item)
    end
    
    for item_idx, item in ipairs(sel_items) do
        -- randomize position only if range > 0
        local org_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        if max_pos - min_pos > 0 then
            local random_pos = RandomNumberFloat(min_pos, max_pos, true)/1000
            local new_pos = org_pos + random_pos 
            reaper.SetMediaItemInfo_Value(item, 'D_POSITION', new_pos)
        --elseif max_pos == 0 and min_pos == 0 then
            --reaper.SetMediaItemInfo_Value(item, 'D_POSITION', org_pos)
        end
        
        -- randomize active take 
        local takes = reaper.CountTakes(item)
        if randomize_takes then 
            if takes > 1 then
                local random_take = math.random(takes) - 1
                local newtake = reaper.GetTake(item, random_take)
                reaper.SetActiveTake(newtake)
            end
        end
        
        -- randomize take parameters
        if takes > 0 then 
            local activetake = reaper.GetActiveTake(item)
            
            -- randomize pitch only if range > 0
            if max_pitch - min_pitch > 0 then
                local random_pitch = RandomNumberFloat(min_pitch, max_pitch, true)
                reaper.SetMediaItemTakeInfo_Value(activetake, 'D_PITCH', random_pitch)
            end
            
            -- randomize volume only if range > 0
            if max_vol - min_vol > 0 then
                local random_volume = RandomNumberFloat(min_vol, max_vol, true)
                local new_volume = dBToLinear(random_volume)
                reaper.SetMediaItemTakeInfo_Value(activetake, 'D_VOL' , new_volume)
            elseif max_vol == 0 and min_vol == 0 then
                -- Reset volume to 0dB if both values are 0
                reaper.SetMediaItemTakeInfo_Value(activetake, 'D_VOL', 1.0) -- 0dB = 1.0 in linear scale
            end
            
            -- randomize rate only if range > 0
            if max_rate - min_rate > 0 then
                local new_rate = RandomNumberFloat(min_rate, max_rate, true)
                local prev_rate = reaper.GetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE')
                local ratio = new_rate/prev_rate
                
                local prev_length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
                local new_length = prev_length / ratio
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', new_length)
                reaper.SetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE', new_rate)
            elseif max_rate == 0 and min_rate == 0 then
                -- Reset playrate to 1.0 if both values are 0
                local prev_rate = reaper.GetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE')
                local ratio = 1.0/prev_rate
                
                local prev_length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
                local new_length = prev_length / ratio
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', new_length)
                reaper.SetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE', 1.0)
            end

            -- randomize content 
            if Settings.content.range > 0 then  -- Only randomize content if range is greater than 0
                local new_offset = min_cont + (math.random() * (max_cont - min_cont))
                reaper.SetMediaItemTakeInfo_Value(activetake, "D_STARTOFFS", new_offset)
            end
        end
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, 'mc_randomizer', -1)
end
