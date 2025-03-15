-- @author mcheung
-- @version 1.2
-- Function to rename duplicate regions, useful for render export regions
-- script to auto increment selected items with _01, _02, _03

function get_item_name(item)
    local take = reaper.GetActiveTake(item)
    if not take then return nil end
    local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    return name
end

function set_item_name(item, new_name)
    local take = reaper.GetActiveTake(item)
    if take then
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
    end
end

function remove_extension(filename)
    return filename:gsub("%.[^.]+$", "")
end

function strip_number_suffix(name)
    local base, number = name:match("^(.-)_(%d%d)$")
    if base and number then
        return base, tonumber(number)
    else
        return name, nil
    end
end

function group_items_by_base_name(items)
    local groups = {}

    for _, item in ipairs(items) do
        local name = get_item_name(item)
        local name_no_ext = remove_extension(name)

        local base_name, _ = strip_number_suffix(name_no_ext)
        if not base_name then
            base_name = name_no_ext 
        end

        if not groups[base_name] then
            groups[base_name] = {}
        end

        table.insert(groups[base_name], item)
    end

    return groups
end

function rename_grouped_items() ----- main
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end


    local items = {}
    for i = 0, item_count - 1 do
        table.insert(items, reaper.GetSelectedMediaItem(0, i))
    end


    local groups = group_items_by_base_name(items)

    -- Rename each group sequentially
    for base_name, group_items in pairs(groups) do
        for index, item in ipairs(group_items) do
            local new_name = string.format("%s_%02d", base_name, index)
            set_item_name(item, new_name)
        end
    end
end

reaper.Undo_BeginBlock()
rename_grouped_items()
reaper.Undo_EndBlock("auto increment items", -1)

