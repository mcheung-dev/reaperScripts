-- @author mcheung 
-- @version 1.0 
-- script that allows you to modify item rate with mousewheel
multiplier_amount = 0.10

local is_new, filename, sectionID, cmdID, mode, resolution, val = reaper.get_action_context() 
min_pitch_rate = 0.001

if val == 0 or not is_new then return end
local rateMod = (val > 0) and multiplier_amount or -multiplier_amount

reaper.Main_OnCommand(40528, 0) -- Item: Open in built-in media explorer (preview)

item = reaper.GetSelectedMediaItem(0, 0)
if not item then return end

local total_takes = reaper.GetMediaItemNumTakes(item)
for i = 0, total_takes - 1 do
    local take = reaper.GetMediaItemTake(item, i)
    if take then
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local perserve_pitch = reaper.GetMediaItemTakeInfo_Value(take, "B_PPITCH")
        
        if perserve_pitch == 1 then
            reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", 0)
        end
        
        if playrate >= min_pitch_rate or rateMod < 0 then
            local newRate = playrate * (1 - rateMod)
            local newLength = length / (1 - rateMod)

            reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newRate)
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", newLength)
        end
    end
end

reaper.UpdateArrange()
reaper.defer(function() end) -- using defer function because script may be ran repeatedly 