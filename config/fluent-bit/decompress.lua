-- decompress.lua: Decompress gzipped VPC flow logs

-- Try loading zlib module with error handling
local ok, zlib = pcall(require, "zlib")
if not ok then
    error("Failed to load zlib module: " .. tostring(zlib))
end

function decompress(tag, timestamp, record)
    -- Skip if already processed
    if record.log ~= nil then
        return 0, timestamp, record
    end

    local content = record.message
    if content == nil or #content == 0 then
        return 1, timestamp, {}
    end

    -- Try to decompress content
    local status, decompressed
    status, decompressed = pcall(function()
        -- Try different decompression methods
        local inflated
        
        -- Try first approach
        inflated = zlib.inflate()(content)
        if inflated then return inflated end
        
        -- If that fails, try with gzip header
        return zlib.inflate()(content, 31)
    end)

    if not status or not decompressed then
        -- If decompression fails, tag the record and pass it through
        record.decompress_error = true
        return 1, timestamp, record
    end

    -- Split decompressed content by newlines
    local logs = {}
    for line in decompressed:gmatch("[^\r\n]+") do
        if line and #line > 0 then
            table.insert(logs, {log = line, path = record.path})
        end
    end

    return #logs, timestamp, logs
end

return {decompress = decompress}