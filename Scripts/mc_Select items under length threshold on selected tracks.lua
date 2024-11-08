-- @author mcheung
-- @version 1.0 
function main()

    userSpecifiedTime = 1
    
    retval, userInput = reaper.GetUserInputs("Select items below length threshold on selected tracks", 1, "Duration", "")
    
    userSpecifiedTime = tonumber(userInput) -- convert string to integer
    
    numofSelectedTracks = reaper.CountSelectedTracks(0)
    
    -- clear selected media items from last instance
    selectedItems = reaper.CountSelectedMediaItems(0)
    
    if selectedItems > 0 then 
    
      unSelectItems = 40289
    
     reaper.Main_OnCommandEx(unSelectItems, 1, 0)
      
    end
    
     -- main function begin
      reaper.Undo_BeginBlock()
  
    if numofSelectedTracks > 0 then 
    
      for i = 0, numofSelectedTracks -1 do
    
        selectedTrack = reaper.GetSelectedTrack(0, i)
        
        itemsOnTrack =  reaper.CountTrackMediaItems(selectedTrack)
        
      if itemsOnTrack > 0 then 
      
      -- loop to check if each media item on track is greater than user specified length
      
       for i = 0, itemsOnTrack - 1 do
      
        item = reaper.GetTrackMediaItem(selectedTrack, i)
        
        itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        -- select items if length is lesser than
        
          if itemLength < userSpecifiedTime then 
        
           reaper.SetMediaItemSelected(item, true)
           
           --removeItems = 40006
           
           --reaper.Main_OnCommandEx(removeItems, 1, 0)
          
           
          end
          
        end
        reaper.Undo_EndBlock("Select all items below length threshold on selected tracks", -1)
    end
end
end
end

  reaper.PreventUIRefresh(1)
   
    main() -- Execute main function
    
    reaper.PreventUIRefresh(-1)
    
    reaper.UpdateArrange()


