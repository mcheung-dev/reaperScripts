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