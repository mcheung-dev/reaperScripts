-- @noindex
--Save function
function save_json(path, var)
    local filepath = path .. ".json"
    local file = assert(io.open(filepath, "w+"))

    local serialized = json.encode(var)
    assert(file:write(serialized))

    file:close()
    return true
end

--Load function
function load_json(path)
    local filepath = path .. ".json"
    local file = assert(io.open(filepath, "rb"))

    local raw_text = file:read("*all")
    file:close()

    return json.decode(raw_text)
end

--- Get and Save
function file_exists(path)
    local f=io.open(path,"r")
    if f~=nil then io.close(f) return true else return false end
end


---
function SavePreset(path, name)
    local t 
    if file_exists(path .. '.json') then
        presets_table = GetPreset(path)
    else
        presets_table = {}
    end
    presets_table[name] = Settings
    save_json(path, presets_table)
end

function GetPreset(path)
    return load_json(path)
end


function DeletePreset(path, name)
    local filepath = path .. ".json"
    if not file_exists(filepath) then
        return false, "Preset file does not exist"
    end

    local presets_table = GetPreset(path)
    if presets_table[name] then
        presets_table[name] = nil
        save_json(path, presets_table)
        return true
    else
        return false, "Preset not found"
    end
end