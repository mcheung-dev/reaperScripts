-- @author mcheung
-- @version 1.0 
function main()
local mouse_pos = reaper.BR_PositionAtMouseCursor(true)

local item = reaper.GetSelectedMediaItem(0, 0)
if item then

  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  

  local new_position = mouse_pos - (item_length / 2)
  

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_position)
  

  reaper.UpdateArrange()
else
  reaper.ShowMessageBox("No item selected", "Error", 0)
end
end

main()
