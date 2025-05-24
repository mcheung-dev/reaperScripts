-- @description Reset Item Rate and Adjust Length with Fade Preservation
-- @author Michael Cheung
-- @version 1.1
-- @about
--   Resets the playback rate of selected media items to 1.0 and adjusts item length to maintain duration
--   Also preserves fade in/out times by scaling them proportionally

function main()
  -- Get the number of selected items
  local item_count = reaper.CountSelectedMediaItems(0)
  
  if item_count == 0 then
    reaper.ShowMessageBox("Please select at least one item.", "No items selected", 0)
    return
  end
  
  -- Begin undo block
  reaper.Undo_BeginBlock()
  
  -- Process each selected item
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      -- Get the active take of the item
      local take = reaper.GetActiveTake(item)
      if take then
        -- Get current item properties
        local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local current_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local fade_in = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
        local fade_out = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        
        -- Calculate scaling factor for length and fades
        local scale_factor = current_rate
        
        -- Calculate new length to maintain content duration
        local new_len = item_len * scale_factor
        
        -- Calculate new fade lengths
        local new_fade_in = fade_in * scale_factor
        local new_fade_out = fade_out * scale_factor
        
        -- Set the playback rate to 1.0 (original rate)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1.0)
        
        -- Set the new item length
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
        
        -- Set the new fade lengths
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", new_fade_in)
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", new_fade_out)
        
        -- Update the item display
        reaper.UpdateItemInProject(item)
      end
    end
  end
  
  -- End undo block
  reaper.Undo_EndBlock("Reset item rate and adjust length with fades", -1)
  
  -- Update the display
  reaper.UpdateArrange()
end

main()