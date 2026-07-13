-- @author mcheung
-- @version 1.0
-- Selects all media items in project and adds them to render queue for Wwise export
-- Compatible with ReaWwise and WAAPI Transfer workflows

function main()
    -- Clear current selection
    reaper.SelectAllMediaItems(0, false)
    
    -- Get total number of media items in project
    local item_count = reaper.CountMediaItems(0)
    
    if item_count == 0 then
        reaper.ShowMessageBox("No media items found in project", "Wwise Export Prep", 0)
        return
    end
    
    -- Select all media items
    for i = 0, item_count - 1 do
        local item = reaper.GetMediaItem(0, i)
        reaper.SetMediaItemSelected(item, true)
    end
    
    -- Clear render queue first
    while reaper.GetRenderQueueItem(0) do
        reaper.RemoveFromRenderQueue(0)
    end
    
    -- Add selected items to render queue
    reaper.Main_OnCommand(41230, 0) -- Item: Add selected items to render queue
    
    -- Get render queue count for confirmation
    local queue_count = 0
    while reaper.GetRenderQueueItem(queue_count) do
        queue_count = queue_count + 1
    end
    
    -- Show confirmation message
    local message = string.format("Selected %d media items and added %d items to render queue.\n\nReady for Wwise export using:\n• ReaWwise extension\n• WAAPI Transfer\n• Manual render", 
                                item_count, queue_count)
    reaper.ShowMessageBox(message, "Wwise Export Prep Complete", 0)
    
    -- Update arrange view to show selection
    reaper.UpdateArrange()
end

-- Run main function
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Select all items for Wwise export", -1) -- hdaksljdlaksjdkl