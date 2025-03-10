

local function showMessage(string, title, errType)
    local userChoice = reaper.MB(string, title, errType)
    return userChoice
end

if not reaper.APIExists("CF_GetSWSVersion") then
    local userChoice = showMessage("This script requires the SWS Extension to run. Would you like to download it ?", "Error", 4)
    if userChoice == 6 then
        openURL("https://www.sws-extension.org/")
    else
        return
    end
end

if not reaper.APIExists("ImGui_GetVersion") then
    showMessage("This script requires ReaImGui to run. Please install it with ReaPack.", "Error", 0)
    return
end


local selectedItems = {}
local silenceItems = {}
local lastTrack = nil


-------------------------------------------------------------------------------------------
------------------------------GENERAL FUNCTIONS--------------------------------------------
-------------------------------------------------------------------------------------------

local function getChannelsOfSelectedItem(take)
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return nil end

    local channels = reaper.GetMediaSourceNumChannels(source)
    return channels
end

local function setAllFXStateOnTrack(track, state)
    local fxCount = reaper.TrackFX_GetCount(track)
    for fxIndex = 0, fxCount - 1 do
        reaper.TrackFX_SetEnabled(track, fxIndex, state)
    end
end

local function muteOriginalItem(item, originalTrack)
    reaper.SetMediaTrackInfo_Value(originalTrack, "B_MUTE", 0)
    local itemCount = reaper.GetTrackNumMediaItems(originalTrack)
    local trackItemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    reaper.SetMediaItemInfo_Value(item, "B_MUTE_ACTUAL", 1)
    return trackItemPosition
end

local function getMediaItemAtPosition(track, position)
    local itemCount = reaper.CountTrackMediaItems(track)
    for i = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if item then
            local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            if itemStart == position then
                return item
            end
        end
    end
    return nil
end

local function findChildTrackByName(parentTrack, trackName)
    local parentTrackIdx = reaper.GetMediaTrackInfo_Value(parentTrack, "IP_TRACKNUMBER") - 1
    local trackCount = reaper.CountTracks(0)
    for i = parentTrackIdx + 1, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local isChild = reaper.GetParentTrack(track) == parentTrack
        retval, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if isChild and name == trackName then
            return track
        elseif reaper.GetTrackDepth(track) <= reaper.GetTrackDepth(parentTrack) then
            break
        end
    end
    return nil
end

local function createChildTrack(parentTrack, childTrack, item, trackItemPosition)
    local trackName = "Original item"
    local parentTrackIndex = reaper.CSurf_TrackToID(parentTrack, false)
    reaper.ReorderSelectedTracks(parentTrackIndex, 1)
    local newItem = getMediaItemAtPosition(childTrack, trackItemPosition)
    reaper.MoveMediaItemToTrack(newItem, parentTrack)
    local originalItemTrack = findChildTrackByName(parentTrack, trackName)
    if originalItemTrack then
        reaper.MoveMediaItemToTrack(item, originalItemTrack)
        reaper.DeleteTrack(childTrack)
    else
        reaper.MoveMediaItemToTrack(item, childTrack)
        reaper.GetSetMediaTrackInfo_String(childTrack, "P_NAME", trackName, true)
    end
    reaper.SetMediaItemSelected(item, false)
    reaper.SetMediaItemSelected(newItem, true)
    reaper.UpdateArrange()
    return newItem
end


local function storeSelectedMediaItems()
    local itemCount = reaper.CountSelectedMediaItems(0)
    local selectedItems = {}
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if item and take then
            table.insert(selectedItems, item)
        end
    end
    return selectedItems
end

local function cleanupAfterRender(item, originalTrack, shouldKeepOriginal, selectedItems)
    setAllFXStateOnTrack(originalTrack, true)
    local trackItemPosition = muteOriginalItem(item, originalTrack)
    reaper.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
    local track = reaper.GetMediaItem_Track(item)
    local childTrack = reaper.GetSelectedTrack(0, 0)
    local newItem
    if shouldKeepOriginal then
        newItem = createChildTrack(originalTrack, childTrack, item, trackItemPosition)

    else
        newItem = getMediaItemAtPosition(childTrack, trackItemPosition)
        reaper.MoveMediaItemToTrack(newItem, originalTrack)
        reaper.DeleteTrackMediaItem(originalTrack, item)
        reaper.DeleteTrack(childTrack)
        reaper.SetMediaItemSelected(newItem, true)
    end
    reaper.UpdateArrange()
end

local function addFades()
    local numItems = reaper.CountSelectedMediaItems(0)
    for i = 0, numItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.0001)
        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.1)
    end
end

local function promptUserForNumber(promptTitle, fieldName)
    local userInputsOK, userInput = reaper.GetUserInputs(promptTitle, 1, fieldName, "")
    if userInputsOK then
        local numberInput = tonumber(userInput)
        if numberInput then
            return numberInput
        else
            showMessage("Please enter a valid number.", "Invalid Input", 0)
        end
    end
    return nil
end

local function alignItemWithMarker(markerId, peakTime, alignOnStart)
    local MAX_SEARCH_ITERATIONS = 1000
    local retval, isRegion, position, rgnEnd, name, markrgnIdxNumber, color
    local idx = 0
    local found = false
    repeat
        retval, isRegion, position, rgnEnd, name, markrgnIdxNumber, color = reaper.EnumProjectMarkers3(0, idx)
        if retval and not isRegion and markrgnIdxNumber == markerId then
            found = true
            break
        end
        idx = idx + 1
        if idx >= MAX_SEARCH_ITERATIONS then
            showMessage("Searched for " .. MAX_SEARCH_ITERATIONS .. " markers. Marker ID not found.", "Error", 0)
            return
        end
    until not retval
    if found then
        local selectedItem = reaper.GetSelectedMediaItem(0, 0)
        if selectedItem then
            if alignOnStart then
                reaper.SetMediaItemInfo_Value(selectedItem, "D_POSITION", position)
            else
                local selectedItemPosition = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
                local peakOffset = peakTime - selectedItemPosition
                reaper.SetMediaItemInfo_Value(selectedItem, "D_POSITION", position - peakOffset)
            end
        end
    else
        showMessage("Marker with ID " .. markerId .. " not found.", "Error", 0)
    end
end

local function spaceSelectedItems(amount)
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount < 2 then return end
    local prevItem = reaper.GetSelectedMediaItem(0, 0)
    local prevItemEnd = reaper.GetMediaItemInfo_Value(prevItem, "D_LENGTH") + reaper.GetMediaItemInfo_Value(prevItem, "D_POSITION")
    for i = 1, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local newPosition = prevItemEnd + amount
        reaper.SetMediaItemPosition(item, newPosition, false)
        prevItemEnd = newPosition + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    end
end

local function getSelectedItemPlayrate(take)
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    return playrate
end

local function bounceInPlace(item, track, shouldKeepOriginal, selectedItems)
    local take = reaper.GetActiveTake(item)
    reaper.SetOnlyTrackSelected(track)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemEnd = itemStart + itemLength
    reaper.GetSet_LoopTimeRange(true, false, itemStart, itemEnd, false)
    local numChannels = getChannelsOfSelectedItem(take)
    setAllFXStateOnTrack(track, false)
    if numChannels == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERMONOSMART"), 0)
    else
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART"), 0)
    end
    cleanupAfterRender(item, track, shouldKeepOriginal, selectedItems)
end

local function audioIsWav(take)
    if take then
        local source = reaper.GetMediaItemTake_Source(take)
        local sourceType = reaper.GetMediaSourceType(source, "")
        return sourceType == "WAVE"
    end
    return false
end

local function hasBeenStretchedFunction(take, item, track)
    local retval = reaper.GetTakeNumStretchMarkers(take)
    local playrate = getSelectedItemPlayrate(take)
    local epsilon = 0.1

    if retval > 0 then
        return true, "The item has stretch markers."
    elseif math.abs(playrate - 1) > epsilon then
        return true, "The item's playrate has been altered."
    else
        return false, ""
    end
end

local function getUserInput()
    local retval, userMarkerId = reaper.GetUserInputs("Enter Marker ID", 1, "Marker ID:", "")
    local markerId = tonumber(userMarkerId)
    if userMarkerId:match("^%d+$") then
        local markerId = tonumber(userMarkerId)
        return markerId, retval
    else
        showMessage("Marker ID not found.", "Error", 0)
        return markerId, false
    end
end

-------------------------------------------------------------------------------------------
-------------------------------------BUFFER------------------------------------------------
-------------------------------------------------------------------------------------------

local function calculateDownsamplingFactor(totalSamples, numChannels)
    --local maxBufferSize = 4159674
    local maxBufferSize = 3000000
    local maxSamplesPerChannel = maxBufferSize / numChannels
    return math.max(1, math.ceil(totalSamples / maxSamplesPerChannel))
end

local function prepareItemAnalysis(item, take)
    if not take then return end
    local accessor = reaper.CreateTakeAudioAccessor(take)
    local retval, currentSampleRate = reaper.GetAudioDeviceInfo("SRATE")
    local sampleRate = tonumber(currentSampleRate)
    if not sampleRate then
        showMessage("Sample Rate could not be found. Is the Audio Device set ?", "Whoops", 0)
        return
    end
    local numChannels = getChannelsOfSelectedItem(take)
    local startTime = reaper.GetAudioAccessorStartTime(accessor)
    local endTime = reaper.GetAudioAccessorEndTime(accessor)
    return accessor, sampleRate, numChannels, startTime, endTime
end

local function calculateTotalSamples(startTime, endTime, sampleRate)
    return math.floor((endTime - startTime) * sampleRate)
end

local function populateBufferWithDownsampling(accessor, sampleRate, numChannels, startTime, totalSamples, isSilence)
    local downsamplingFactor = calculateDownsamplingFactor(totalSamples, numChannels)
    if isSilence then
        downsamplingFactor = downsamplingFactor * 80
    end
    local totalBlocks = math.ceil(totalSamples / downsamplingFactor)
    local buffer = reaper.new_array(totalBlocks * numChannels)
    buffer.clear()
    for i = 0, totalBlocks - 1 do
        local blockStartTime = startTime + (i * downsamplingFactor / sampleRate)
        local blockBuffer = reaper.new_array(numChannels)
        blockBuffer.clear()
        reaper.GetAudioAccessorSamples(accessor, sampleRate, numChannels, blockStartTime, 1, blockBuffer)
        for ch = 1, numChannels do
            buffer[i * numChannels + ch] = blockBuffer[ch]
        end
    end
    return buffer, downsamplingFactor, totalBlocks
end


local function getBufferReady(item, isSilence, take)
    local accessor, sampleRate, numChannels, startTime, endTime = prepareItemAnalysis(item, take)
    if not sampleRate then return end
    local totalSamples = calculateTotalSamples(startTime, endTime, sampleRate)
    local buffer, downsamplingFactor, numSamplesInBuffer = populateBufferWithDownsampling(accessor, sampleRate, numChannels, startTime, totalSamples, isSilence)
    return buffer, numSamplesInBuffer, numChannels, downsamplingFactor, accessor, sampleRate, startTime
end

-------------------------------------------------------------------------------------------
--------------------------------------PEAK-------------------------------------------------
-------------------------------------------------------------------------------------------

local function findPeakInBuffer(buffer, numSamplesInBuffer, numChannels, downsamplingFactor)
    local peakValue = 0
    local peakIndex = 0
    for i = 1, numSamplesInBuffer do
        local bufferIndex = (i - 1) * numChannels + 1
        if bufferIndex <= #buffer then
            for channel = 1, numChannels do
                local sampleIndex = bufferIndex + (channel - 1)
                if sampleIndex <= #buffer then
                    local sample = buffer[sampleIndex]
                    if sample > peakValue then
                        peakValue = sample
                        peakIndex = i
                    end
                end
            end
        end
    end
    peakIndex = peakIndex * downsamplingFactor
    return peakValue, peakIndex
end

local function calculatePeakTime(take, item, peakIndex, sampleRate)
    local takeStartOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local peakTimeRelativeToSource = takeStartOffset + (peakIndex / sampleRate)
    local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local peakTimeRelativeToProject = itemPosition + peakTimeRelativeToSource
    local itemStartPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local peakTime = itemStartPos + (peakIndex / sampleRate)

    if peakTimeRelativeToSource < 0 then peakTimeRelativeToSource = 0 end
    return peakTime
end

local function getPeakTime(item, take)
    local isSilence = false
    local peakBuffer, numSamplesInBuffer, numChannels, downsamplingFactor, peakAccessor, sampleRate, startTime = getBufferReady(item, isSilence, take)
    if not sampleRate then return end
    local peakValue, peakIndex = findPeakInBuffer(peakBuffer, numSamplesInBuffer, numChannels, downsamplingFactor)
    local peakTime = calculatePeakTime(take, item, peakIndex, sampleRate)
    reaper.DestroyAudioAccessor(peakAccessor)
    return peakTime
end

-------------------------------------------------------------------------------------------
------------------------------------SILENCES-----------------------------------------------
-------------------------------------------------------------------------------------------

local function detectSilences(buffer, silenceThreshold, minSilenceDuration, sampleRate, downsamplingFactor, numChannels)
    local silences = {}
    local silenceStartIndex = nil
    local currentSilenceDuration = 0
    local minSilenceSamples = minSilenceDuration * sampleRate / downsamplingFactor * numChannels

    for i = 1, #buffer do
        local sample = math.abs(buffer[i])
        local isSilent = sample <= silenceThreshold

        if isSilent then
            if silenceStartIndex == nil then
                silenceStartIndex = i
            end
            currentSilenceDuration = currentSilenceDuration + 1
        else
            if silenceStartIndex and currentSilenceDuration >= minSilenceSamples then
                local silenceEndTimeIndex = silenceStartIndex + currentSilenceDuration - 1
                table.insert(silences, { start = silenceStartIndex, ["end"] = silenceEndTimeIndex })
            end
            silenceStartIndex = nil
            currentSilenceDuration = 0
        end
    end

    if silenceStartIndex and currentSilenceDuration >= minSilenceSamples then
        local silenceEndTimeIndex = silenceStartIndex + currentSilenceDuration - 1
        table.insert(silences, { start = silenceStartIndex, ["end"] = silenceEndTimeIndex })
    end
    return silences
end

local function convertSilencesToTime(silences, startTime, sampleRate, downsamplingFactor, numChannels)
    local silencesInTime = {}
    for _, silence in ipairs(silences) do
        local startInTime = startTime + ((silence.start / numChannels) * downsamplingFactor - downsamplingFactor) / sampleRate
        local endInTime = startTime + ((silence["end"] / numChannels) * downsamplingFactor - downsamplingFactor) / sampleRate
        if startInTime < 0 then
            startInTime = 0
        end

        table.insert(silencesInTime, { start = startInTime, ["end"] = endInTime })
    end
    return silencesInTime
end

local function deleteSilencesFromItem(item, silences)
    if not item or #silences == 0 then
        return
    end
    reaper.PreventUIRefresh(1)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    for i = #silences, 1, -1 do
        local silence = silences[i]
        local silenceStart = itemStart + silence.start
        local silenceEnd = itemStart + silence["end"]
        if silenceEnd < silenceStart then
            silenceEnd = silenceStart
        end
        if silenceStart == itemStart then
            local splitItemEnd = reaper.SplitMediaItem(item, silenceEnd)
            if splitItemEnd then
                reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
            end
        else
            local splitItemEnd = reaper.SplitMediaItem(item, silenceEnd)
            local splitItemStart = reaper.SplitMediaItem(item, silenceStart)
            if splitItemStart then
                reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(splitItemStart), splitItemStart)
            end
        end
    end
    reaper.PreventUIRefresh(-1)

    reaper.UpdateArrange()
end



local function deleteShortItems(coeff)
    local selectedItemsCount = reaper.CountSelectedMediaItems(0)
    if selectedItemsCount == 0 then return end

    local totalLength = 0
    for i = 0, selectedItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        totalLength = totalLength + length
    end

    local averageLength = totalLength / selectedItemsCount
    local minLength = averageLength / coeff

    for i = selectedItemsCount - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        if length < minLength then
            local track = reaper.GetMediaItem_Track(item)
            reaper.DeleteTrackMediaItem(track, item)
        end
    end
end

local function createTemporaryItems(track, silences, itemPosition)
    lastTrack = track
    local redColor = reaper.ColorToNative(255, 0, 0) | 0x1000000
    for _, silence in ipairs(silences) do
        local silenceStart = itemPosition + silence.start
        local silenceEnd = itemPosition + silence["end"]
        local silenceLength = silenceEnd - silenceStart

        local newItem = reaper.AddMediaItemToTrack(track)
        reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", silenceStart)
        reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", silenceLength)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEINLEN", 0)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEOUTLEN", 0)

        reaper.SetMediaItemInfo_Value(newItem, "I_CUSTOMCOLOR", redColor)
        table.insert(silenceItems, newItem)
    end
end

local function clearTemporaryItems()
    for _, item in ipairs(silenceItems) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            local track = reaper.GetMediaItem_Track(item)
            reaper.DeleteTrackMediaItem(track, item)
        end
    end
    silenceItems = {}
end

local function cleanup()
        clearTemporaryItems()
        reaper.UpdateArrange()
end

local function getSilenceTime(item, take)
    local isSilence = true
    local silenceBuffer, numSamplesInBuffer, numChannels, downsamplingFactor, silenceAccessor, sampleRate, startTime = getBufferReady(item, isSilence, take)
    if not sampleRate then return end
    local silences = detectSilences(silenceBuffer, silenceThreshold, minSilenceDuration, sampleRate, downsamplingFactor, numChannels)
    local silencesInTime = convertSilencesToTime(silences, startTime, sampleRate, downsamplingFactor, numChannels)
    reaper.DestroyAudioAccessor(silenceAccessor)
    --adjustSilenceTimes(silencesInTime, -0.1, -0.0001)
    return silencesInTime
end

-------------------------------------------------------------------------------------------
---------------------------------MAIN FUNCTIONS--------------------------------------------
-------------------------------------------------------------------------------------------

local function getSelectedItemsBounds(selectedItemsCount)
    local minPos, maxEnd = math.huge, -math.huge

    for i = 0, selectedItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd = itemPos + itemLength

        minPos = math.min(minPos, itemPos)
        maxEnd = math.max(maxEnd, itemEnd)
    end

    return minPos, maxEnd
end

local function implodeToTakesKeepPosition()
    local selectedItemsCount = reaper.CountSelectedMediaItems(0)
    if selectedItemsCount < 1 then return end

    local minPos, maxEnd = getSelectedItemsBounds(selectedItemsCount)

    for i = 0, selectedItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
        reaper.BR_SetItemEdges(item, minPos, maxEnd)
    end

    reaper.Main_OnCommand(40543, 0) -- Command ID for "Take: Implode items on same track into takes"
end

local function alignItemsByPeakTime()
    local numItems = reaper.CountSelectedMediaItems(0)
    if numItems < 2 then return end

    local firstItem = reaper.GetSelectedMediaItem(0, 0)
    local takeFirstItem = reaper.GetActiveTake(firstItem)
    local firstPeakTime = getPeakTime(firstItem, takeFirstItem)
    if not firstPeakTime then return end

    for i = 1, numItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        local peakTime = getPeakTime(item, take)
        if not peakTime then return end
        if peakTime then
            local offset = firstPeakTime - peakTime
            local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local newPosition = itemPosition + offset
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPosition)
        end
    end
    return firstPeakTime
end

local function alignItemsByStartPosition()
    local numItems = reaper.CountSelectedMediaItems(0)
    if numItems < 2 then return end

    local earliestStart = math.huge
    for i = 0, numItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        if itemPosition < earliestStart then
            earliestStart = itemPosition
        end
    end

    for i = 0, numItems - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", earliestStart)
    end
    return earliestStart
end

local function splitMain(item, take, splitAndSpace)
    local silencesInLoop = getSilenceTime(item, take)
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
    deleteSilencesFromItem(item, silencesInLoop)
    deleteShortItems(3)
    if splitAndSpace then
        spaceSelectedItems(1)
        addFades()
    end
end

local function implodeMain(item, take, onPeak, alignOnStart, silencesInLoop, shouldAlignToMarker, userMarkerChoice)
    local firstPeakTime
    local splitAndSpace = false
    splitMain(item, take, splitAndSpace)
    addFades()
    if onPeak then
        firstPeakTime = alignItemsByPeakTime()
        if not firstPeakTime then return end
    else
        alignItemsByStartPosition()
    end
    implodeToTakesKeepPosition()
    if shouldAlignToMarker then
        if onPeak then
            if firstPeakTime ~= nil then
                alignItemWithMarker(userMarkerChoice, firstPeakTime, alignOnStart)
            else
                showMessage("Could not retrieve Peak Amplitude. Was the item already collapsed ?", "Whoops!", 0)
            end
        else
            alignItemWithMarker(userMarkerChoice, firstPeakTime, true)
        end
    end
end

function getMarkerPosition(markerId)
    local num_markers, num_regions = reaper.CountProjectMarkers(0)
    local total_markers_and_regions = num_markers + num_regions
    for i = 0, total_markers_and_regions - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if not isrgn and markrgnindexnumber == markerId then
            return pos
        end
    end
    return nil
end

function alignItemsToMarker(markerId, onPeak, shouldAlignToMarker, item)
    local markerPos
    if shouldAlignToMarker then
        markerPos = getMarkerPosition(markerId)
    else
        markerPos = reaper.GetCursorPosition()
    end
    if markerPos == nil then
        showMessage("Marker with the specified ID does not exist.", "Error", 0)
        return
    end

    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount < 1 then return end

    if onPeak then
        for i = 0, itemCount - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local take = reaper.GetActiveTake(item)
            local track = reaper.GetMediaItem_Track(item)
            local childTrack = findChildTrackByName(track, "Original item")
            local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local newItem = nil
            if childTrack then
                newItem = getMediaItemAtPosition(childTrack, itemPos)
            end
            if take ~= nil then
                local peakTime = getPeakTime(item, take)
                local offset = peakTime - itemPos
                local newPos = markerPos - offset

                reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPos)
                if childTrack and newItem then
                    reaper.SetMediaItemInfo_Value(newItem, "D_POSITION", newPos)
                end
            end
        end
    else
        for i = 0, itemCount - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", markerPos)
        end
    end
end

function tableIsEmpty(table)
    for _ in pairs(table) do
        return false
    end
    return true
end

local function itemsAreValid(selectedItems)
    if not tableIsEmpty(selectedItems) then
        local itemsToConvert = {}
        local errorMessages = {}
        for _, item in ipairs(selectedItems) do
            local take = reaper.GetActiveTake(item)
            local track = reaper.GetMediaItem_Track(item)
            local isWav = audioIsWav(take)
            local hasBeenStretched, stretchErrorMessage = hasBeenStretchedFunction(take, item, track)
            if not isWav then
                table.insert(itemsToConvert, item)
                table.insert(errorMessages, "The item is not in WAV format.")
            elseif hasBeenStretched then
                table.insert(itemsToConvert, item)
                table.insert(errorMessages, stretchErrorMessage)
            end
        end
        if tableIsEmpty(itemsToConvert) then
            return nil
        else
            return itemsToConvert, errorMessages
        end
    end
    return nil
end


local function unselectEveryItem()
    local itemCount = reaper.CountMediaItems(0)
    for i = 0, itemCount - 1 do
        local currentItem = reaper.GetMediaItem(0, i)
        reaper.SetMediaItemSelected(currentItem, false)
    end
end

local function askForBounce(shouldKeepOriginal, itemsToConvert, errorMessages)
    local message = table.concat(errorMessages, "\n") .. "\nAnalysing it might freeze REAPER. \nWould you like to create a usable copy?"
    local userChoice = showMessage(message, "Warning", 4)
    if userChoice == 6 then
        for i, item in ipairs(itemsToConvert) do
            local track = reaper.GetMediaItem_Track(item)
            bounceInPlace(item, track, shouldKeepOriginal, itemsToConvert)
        end
        return true
    else
        unselectEveryItem()
        return false
    end
end

local function selectOnlyThisItem(item)
    unselectEveryItem()
    if item then
        reaper.SetMediaItemSelected(item, true)
    end
end

local function safeToExecute(selectedItems)
    cleanup()
    local itemsToConvert, errorMessages = itemsAreValid(selectedItems)
    if itemsToConvert then
        reaper.Undo_BeginBlock()
        local goodToGo = askForBounce(shouldKeepOriginal, itemsToConvert, errorMessages)
        reaper.Undo_EndBlock("Bounce in place.", -1)
        return goodToGo
    else
        return true
    end
end


-------------------------------------------------------------------------------------------
---------------------------------------UI--------------------------------------------------
-------------------------------------------------------------------------------------------


silenceThreshold = 0.01
minSilenceDuration = 0.2

local activeMode
local activeModeChanged
if activeRetValString ~= "" then
    activeMode = (activeRetValString == "true")
else
    activeMode = true
end

local shouldKeepOriginal
local shouldKeepOriginalChanged
local shouldKeepOriginalRetValString = reaper.GetExtState("randomizer", "shouldKeepOriginal")
if shouldKeepOriginalRetValString ~= "" then
    shouldKeepOriginal = (shouldKeepOriginalRetValString == "true")
else
    shouldKeepOriginal = true
end

local alignToMarkerChanged = false
local isWav = true
local hasBeenStretched = false
local splitAndSpace = false

local function ResetItemLength()
    local num_items = reaper.CountSelectedMediaItems(0)
    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take then
            local source = reaper.GetMediaItemTake_Source(take)
            local source_length, _ = reaper.GetMediaSourceLength(source)
    
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", source_length)
        end
    end
end


--- main function 
-- function CompileTakes()
--     cleanup()
--     reaper.Undo_BeginBlock()
--     if safeToExecute(selectedItems) then
--         ResetItemLength()
--         local userMarkerChoice = nil
--         if shouldAlignToMarker then
--             userMarkerChoice = promptUserForNumber("Align with marker", "Please enter the Marker ID")
--         end
--         local selectedItems = storeSelectedMediaItems()
--         for i, item in ipairs(selectedItems) do
--             selectOnlyThisItem(item)
--             local take = reaper.GetActiveTake(item)
--             local track = reaper.GetMediaItem_Track(item)
--             local onPeak = false
--             local alignOnStart = true
--             implodeMain(item, take, onPeak, alignOnStart, silencesInLoop, shouldAlignToMarker, userMarkerChoice)
--         end
--         reaper.UpdateArrange()
--     else
--         askForBounce(item, track, shouldKeepOriginal)
--     end
--     reaper.Undo_EndBlock("Implode to takes (start).", -1)
-- end

--- TO TEST 1--------------------------------------------------------------------------------
function CompileTakes()
    cleanup()
    reaper.Undo_BeginBlock()
    
    local selectedItems = storeSelectedMediaItems()
    if not selectedItems or #selectedItems == 0 then
        reaper.ShowConsoleMsg("Error: No selected items found.\n")
        return
    end

    ResetItemLength()
    local userMarkerChoice = nil
    if shouldAlignToMarker then
        userMarkerChoice = promptUserForNumber("Align with marker", "Please enter the Marker ID")
    end

    -- Store the original take for the first item
    local originalTake = nil
    local originalLength = {}

    for i, item in ipairs(selectedItems) do
        selectOnlyThisItem(item)
        local take = reaper.GetActiveTake(item)
        local track = reaper.GetMediaItem_Track(item)
        local onPeak = false
        local alignOnStart = true
        
        -- Store the original take for the first item
        if i == 1 then
            originalTake = take
        end
        
        originalLength[item] = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- Implode takes
        implodeMain(item, take, onPeak, alignOnStart, silencesInLoop, shouldAlignToMarker, userMarkerChoice)

        -- Ensure original take is first for the first item
        local item = reaper.GetSelectedMediaItem(0, 0)
        if i == 1 and originalTake then
            local newTakeCount = reaper.GetMediaItemNumTakes(item)
            if newTakeCount > 1 then
                for takeIndex = 0, newTakeCount - 1 do
                    local takeAtIndex = reaper.GetMediaItemTake(item, takeIndex)
                    if takeAtIndex == originalTake then
                        if takeIndex ~= 0 then
                            reaper.SetActiveTake(originalTake)
                            reaper.Main_OnCommand(41359, 0) -- Move active take to the first position
                        end
                        break
                    end
                end
            end
        end

        if originalLength[item] then
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", originalLength[item])
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Implode to takes (start).", -1)
end
----- test 2