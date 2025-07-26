local FILE = {}
local binser = require "libs.binser"
local bitser = require "mobile_libs.bitser"

local serializer_used

function FILE.serialize(data)
    if serializer_used == 'bitser' then
        return bitser.dumps(data)
    else
        return binser.serialize(data)
    end
end

function FILE.deserialize(data)
    if serializer_used == 'bitser' then
        return bitser.loads(data)
    else
        return binser.deserialize(data)[1]
    end
end

function FILE.read(path)
    if love.filesystem.getInfo(path) then
        return FILE.deserialize(love.filesystem.read(path))
    else
        error("No file: "..path)
    end
end

function FILE.write(path, data)
    love.filesystem.write(path, FILE.serialize(data))
end

---@param lib_name 'bitser'|'binser'
---Init the FILE module with chosen serializer
return function(lib_name)
    assert(lib_name == 'bitser' or lib_name == 'binser', '[lib_name] must be "bitser" or "binser"')
    serializer_used = lib_name
    return FILE
end