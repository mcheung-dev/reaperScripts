
-- @author mcheung
-- @version 1.0 

function main()
local mouse_pos = reaper.BR_PositionAtMouseCursor(true)

-- Check if an item is selected
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
  -- Get item information
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  
  -- Calculate new position to center the item on the mouse position
  local new_position = mouse_pos - (item_length / 2)
  
  -- Set the item's new position
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_position)
  
  -- Update the arrange view
  reaper.UpdateArrange()
else
  reaper.ShowMessageBox("No item selected", "Error", 0)
end
end

main()
