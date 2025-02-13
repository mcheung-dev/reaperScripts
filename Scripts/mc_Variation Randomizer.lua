-- User settings
local min_pos = -200 -- in ms
local max_pos = 200

local min_pitch = 0 
local max_pitch = 12

local min_rate = 1 -- can't be 0, lowest is 1
local max_rate = 2

local min_take = 1
local max_take = 2

local min_vol = -6 -- in dB
local max_vol = 6

local lower_value = 0.0001
if min_rate <= 0 then 
  min_rate = lower_value
end




---Map/Scale Val between range 1 (min1 - max1) to range 2 (min2 - max2)
---@param value number Value to be mapped
---@param min1 number Range 1 min
---@param max1 number Range 1 max
---@param min2 number Range 2 min
---@param max2 number Range 2 max
---@return number
function MapRange(value,min1,max1,min2,max2)
    return (value - min1) / (max1 - min1) * (max2 - min2) + min2
end

---Generate a random number between min and max.
---@param min number minimum value
---@param max number maximum value
---@param is_include_max boolean if true it can result on the max value
---@return number
function RandomNumberFloat(min,max,is_include_max)
    local sub = (is_include_max and 0) or 1 --  -1 because it cant never be the max value. Lets say we want to choose random between a and b a have 2/3 chance and b 1/3. If the random value is from 0 - 2(not includded) it is a, if the value is from 2 - 3(not includded) it is b. 
    local big_val = 1000000 -- the bigger the number the bigger the resolution. Using 1M right now
    local random = math.random(0,big_val-sub) -- Generating a very big value to be Scaled to the sum of the chances, for enabling floats.
    random = MapRange(random,0,big_val,min,max) -- Scale the random value to the sum of the chances

    return random
end

--- Return dbval in linear value. 0 = -inf, 1 = 0dB, 2 = +6dB, etc...
function dBToLinear(dbval)
    return 10^(dbval/20) 
end

--- Return value in db. 0 = -inf, 1 = 0dB, 2 = +6dB, etc...
function LinearTodB(value)
    return 20 * math.log(value,10)    
end


----code ---
local proj = 0 
local sel_items = {}
local cnt = reaper.CountSelectedMediaItems(proj)

if cnt == 0 then
  reaper.ShowMessageBox('no items selected', 'error' , 0)
  return
end

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

for i = 0, cnt - 1 do 
  local item = reaper.GetSelectedMediaItem(proj, i)
  table.insert(sel_items, item)
end
  
for item_idx, item in ipairs(sel_items)do
 -- randomize position
  local org_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local random_pos = RandomNumberFloat(min_pos, max_pos, true)/1000
  local new_pos = org_pos + random_pos 
  reaper.SetMediaItemInfo_Value(item, 'D_POSITION', new_pos)
  
 -- randomize active take 
  local takes = reaper.CountTakes(item)
  if takes > 1 then
    local random_take = math.random(takes) - 1
    local newtake = reaper.GetTake(item, random_take)
    reaper.SetActiveTake(newtake)
  end
  
 -- randomize take parameters
  if takes > 0 then 
  -- randomize pitch 
  local activetake = reaper.GetActiveTake(item)
  local random_pitch = RandomNumberFloat(min_pitch, max_pitch, true)
  reaper.SetMediaItemTakeInfo_Value(activetake, 'D_PITCH', random_pitch)
  
  -- randomize volume 
  local random_volume = RandomNumberFloat(min_vol, max_vol, true)
  local new_volume = dBToLinear(random_volume)
  reaper.SetMediaItemTakeInfo_Value(activetake, 'D_VOL' , new_volume)
  
  -- randomize rate 
  local new_rate = RandomNumberFloat(min_rate, max_rate, true)
  local prev_rate = reaper.GetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE')
  local ratio = new_rate/prev_rate
  
  local prev_length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local new_length = prev_length / ratio
  reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', new_length)
  reaper.SetMediaItemTakeInfo_Value(activetake, 'D_PLAYRATE', new_rate)
  

  
  end

end

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock2(0, 'mc_randomizer', -1)
reaper.UpdateArrange()


