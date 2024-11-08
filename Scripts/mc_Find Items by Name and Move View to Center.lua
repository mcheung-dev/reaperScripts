
-- @author mcheung
-- @version 1.0 

function main()
    -- count all the items in the session and store as variable 
    local numOfItems =  reaper.CountMediaItems(0)
    -- prompt the user for desired string 
    local retval, strToSearchFor = reaper.GetUserInputs('Search for', 1, 'Enter item name to search for', '')

    strToSearchFor = string.lower(strToSearchFor)
    -- check if user actually gave a string 
    -- check that user clicked OK ()
    -- if user pressed ESC or ENTER with an empty string, then we dont want to proceed 
    if (retval == true and strToSearchFor ~= '') then 
      
        local matchFound = false 
        for i = 0, numOfItems - 1 do

            local mediaItem = reaper.GetMediaItem(0, i)
            local itemTake = reaper.GetActiveTake(mediaItem)
            local takeName = reaper.GetTakeName(itemTake)

            takeName = string.lower(takeName)

            if strToSearchFor == takeName then 
                
                -- if this item is first to be found, then 
                    if matchFound == false then
                        matchFound = true

                        local thisItemStartPos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
                        local thisItemLength = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
                        local halfItemLength = thisItemLength / 2

                        local isSet = false 
                        local currentViewStartPos, currentViewEndPos = reaper.GetSet_ArrangeView2 (0, isSet, 0, 0)
                        local currentViewWidth = currentViewEndPos - currentViewStartPos
                        local halfCurrentViewWidth = currentViewWidth / 2

                        local newStartPos = (thisItemStartPos + halfItemLength) - halfCurrentViewWidth
                        local newEndPos = (thisItemStartPos + halfItemLength) + halfCurrentViewWidth
                
                -- move the screen to focus on this item 
                -- we want the view to not have zoomed in or out after moving 
                -- we want the view to centre on the center of the item

                        isSet = true 
                        reaper.GetSet_ArrangeView2 (0, isSet, 0, 0, newStartPos, newEndPos)
                        end

                -- set item to selected
                reaper.SetMediaItemSelected(mediaItem, true)
            end


            for i = 0, numOfItems - 1 do

                local mediaItem = reaper.GetMediaItem(0, i)
                local itemTake = reaper.GetActiveTake(mediaItem)
                local takeName = reaper.GetTakeName(itemTake)
                -- using string.find, if it is found, it will return integer, if there is no match, partialMatch will be 0
                local partialMatch = string.find(takeName, strToSearchFor)
    
                if partialMatch then -- does partial match exist or not 
                    reaper.SetMediaItemSelected(mediaItem, true)
                end

            reaper.UpdateTimeline()

        end
      end
end
-- iterate through every item (and region?) in the session 
    -- first want to check for exact match 
    -- if we find a match, 
    -- set all items that are a match to selected 
    -- move timeline view so item is roughly centered 
        -- on first exact match that it found
--end of first iteration block 

-- if we haven't found exact match, now look for partial matches
    --now look for partial matches 
    --each match that we find, set item to selected
    --move timline to look at first we found
end 




main()

