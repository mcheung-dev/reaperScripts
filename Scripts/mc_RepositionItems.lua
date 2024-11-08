
-- @author mcheung
-- @version 1.0 

function main()

-- count selected items 

-- get items starting location & length 
-- get ending position 
-- first item does not move 
-- set next item to prev ending position + user number

userDuration = 0.5

numOfSelectedItems = reaper.CountSelectedMediaItems(0)

firstItem = reaper.GetSelectedMediaItem(0, 0)

if numOfSelectedItems > 1 then 

  firstItemPosition = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION")

  firstItemLength = reaper.GetMediaItemInfo_Value(firstItem, "D_LENGTH")

  prevItemPosition = firstItemPosition + firstItemLength 

    for i = 0, numOfSelectedItems - 1, 1 do 
  
      if i == 0 then 
      
      else 
      
      local item = reaper.GetSelectedMediaItem(0, i)
      
      local newItemPosition = prevItemPosition + userDuration 
      
      reaper.SetMediaItemPosition(item, newItemPosition, true)
      
      local thisItemsLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      
      prevItemPosition = thisItemsLength + newItemPosition 
      
      end
      
    end
    
    end
    
    end

main()
  
  
  
  
  





