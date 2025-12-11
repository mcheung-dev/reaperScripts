-- @author mcheung
-- @version 1.0
-- script that batch renames regions
function GetAllRegions()
    local regions = {}
    local i = 0
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color
    
    repeat
        retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        if retval > 0 and isrgn then
            table.insert(regions, {
                index = i,
                markrgnindexnumber = markrgnindexnumber,
                name = name,
                pos = pos,
                rgnend = rgnend,
                color = color
            })
        end
        i = i + 1
    until retval == 0
    
    return regions
end

-- Function to replace string in region names
function BatchRenameRegions(searchString, replaceString)
    if searchString == "" then
        reaper.ShowMessageBox("Search string cannot be empty!", "Error", 0)
        return 0
    end
    
    local regions = GetAllRegions()
    local count = 0
    
    -- Start undo block
    reaper.Undo_BeginBlock()
    
    for _, region in ipairs(regions) do
        if string.find(region.name, searchString, 1, true) then
            local newName = string.gsub(region.name, searchString, replaceString)
            reaper.SetProjectMarker3(
                0,
                region.markrgnindexnumber,
                true,
                region.pos,
                region.rgnend,
                newName,
                region.color
            )
            count = count + 1
        end
    end
    
    -- End undo block
    reaper.Undo_EndBlock("Batch Rename Regions", -1)
    
    return count
end

-- Main script execution
function Main()
    -- Get search string from user
    local retval1, searchString = reaper.GetUserInputs(
        "Batch Rename Regions - Step 1",
        1,
        "Search for:",
        ""
    )
    
    if not retval1 then
        return -- User cancelled
    end
    
    -- Get replacement string from user
    local retval2, replaceString = reaper.GetUserInputs(
        "Batch Rename Regions - Step 2",
        1,
        "Replace with:",
        ""
    )
    
    if not retval2 then
        return -- User cancelled
    end
    
    -- Perform the batch rename
    local count = BatchRenameRegions(searchString, replaceString)
    
    -- Show result
    if count > 0 then
        reaper.ShowMessageBox(
            string.format("Successfully renamed %d region(s).\n\nSearch: '%s'\nReplace: '%s'", 
                count, searchString, replaceString),
            "Success",
            0
        )
        reaper.UpdateArrange()
    else
        reaper.ShowMessageBox(
            string.format("No regions found containing '%s'", searchString),
            "No Changes",
            0
        )
    end
end

-- Run the script
Main()
