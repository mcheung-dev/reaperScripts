-- Adjustment to script by LEWIS HAINES AUDIO to work for all takes in media item. 
-- @version 1.0 

-- CHANGE THIS TO MODIFY RATE CHANGE INTENSITY
scalingAmount = 0.05

-- GET ACTION CONTEXT & ESTABLISH MINIMUM RATE
local is_new, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context() 
pitchRateMinimum = 0.001

-- GET MOUSE DIRECTION
if val == 0 or not is_new then return end
local rateMod = (val > 0) and scalingAmount or -scalingAmount

-- SELECT ITEM UNDER CURSOR
reaper.Main_OnCommand(40528, 0)

-- GET SELECTED MEDIA ITEM
selItem = reaper.GetSelectedMediaItem(0, 0)
if not selItem then return end

-- LOOP THROUGH ALL TAKES
local numTakes = reaper.GetMediaItemNumTakes(selItem)
for takeIdx = 0, numTakes - 1 do
    local selTake = reaper.GetMediaItemTake(selItem, takeIdx)
    if selTake then
        local curRate = reaper.GetMediaItemTakeInfo_Value(selTake, "D_PLAYRATE")
        local itpPitch = reaper.GetMediaItemTakeInfo_Value(selTake, "B_PPITCH")
        
        if itpPitch == 1 then
            reaper.SetMediaItemTakeInfo_Value(selTake, "B_PPITCH", 0)
        end
        
        if curRate >= pitchRateMinimum or rateMod < 0 then
            local newRate = curRate * (1 - rateMod)
            reaper.SetMediaItemTakeInfo_Value(selTake, "D_PLAYRATE", newRate)
        end
    end
end

-- UPDATE THE MEDIA ITEM LENGTH ONCE
local curLength = reaper.GetMediaItemInfo_Value(selItem, "D_LENGTH")
local newLength = curLength / (1 - rateMod)
reaper.SetMediaItemInfo_Value(selItem, "D_LENGTH", newLength)

-- UPDATE ARRANGE VIEW
reaper.UpdateArrange()
reaper.defer(function() end)
