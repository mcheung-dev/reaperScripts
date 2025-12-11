-- @author mcheung
-- @version 1.1
function main()

  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least one item.", "No items selected", 0)
    return
  end

  reaper.Undo_BeginBlock()

  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local take = reaper.GetActiveTake(item)
      if take then

        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local current_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local fade_in = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        local fade_out = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        
        local scale_factor = current_rate
        
        local new_len = item_len * scale_factor
        
        local new_fade_in = fade_in * scale_factor
        local new_fade_out = fade_out * scale_factor
        
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1.0)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", new_fade_in)
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", new_fade_out)
        reaper.UpdateItemInProject(item)
      end
    end
  end
  
  reaper.Undo_EndBlock("Reset item rate and adjust length with fades", -1)
  reaper.UpdateArrange()
end

main()