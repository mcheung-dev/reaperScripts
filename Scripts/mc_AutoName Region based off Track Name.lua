 -- @author mcheung
-- @version 1.0 
function main()
    -- count selected item
    local numOfSelectedItems = reaper.CountSelectedMediaItems(0)
    -- if there are no selected itmes then dont proceed 
    if numOfSelectedItems > 0 then 
    
        -- prompt user if they want underscore or space bar 
       retval, userInputUnderscore = reaper.GetUserInputs("Replace spaces with underscore?", 1, 'Type y or n', '')

       local replaceSpaceWithUnderscore = false 
        if userInputUnderscore == "y" then 
            replaceSpaceWithUnderscore = true 
        end
         -- keep track of running index 
        local runningIndex = 1
         -- keep track of previous items track name 
        local previousTrackName = ''

        for i = 0, numOfSelectedItems - 1 do 

            local mediaItem = reaper.GetSelectedMediaItem(0, i)
            local startPos = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
            local itemLength = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
            local endPos = startPos + itemLength 

            local track = reaper.GetMediaItemTrack(mediaItem)

            local parentTrack = reaper.GetParentTrack(track)

            if parentTrack then 
                track = parentTrack 
            end
            
            local retval, trackName = reaper.GetTrackName(parentTrack)

            if trackName == previousTrackName then
                runningIndex = runningIndex + 1

            elseif trackName ~= previousTrackName then 
                runningIndex = 1
            end
            previousTrackName = trackName
            
            local isRegion = true 
            regionName = trackName .. " " .. runningIndex 

            if replaceSpaceWithUnderscore == true then 
                regionName = string.gsub(regionName, ' ', "_")
            end

            
            reaper.Undo_BeginBlock()
            reaper.AddProjectMarker(0, isRegion, startPos, endPos, regionName, 0)
        end
        reaper.Undo_EndBlock("Undo AutoName Regions based off Track Name ", -1)
    end
end

main()
    

    --in a for loop, for as many items are selected do
        -- get reference to item 
        -- get start position of item 
        -- get length of item 
        -- endpos = start position + length 
        -- get reference to items parent track 
        -- get parent track name 
        -- if this track name is same as previous items name, increase index 
        -- if not, reset index 
        -- create region 




