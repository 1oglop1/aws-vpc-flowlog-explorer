-- extract_path_metadata.lua: Extract metadata from file path

function extract_metadata(tag, timestamp, record)
    local path = record.path
    if not path then
        return 0, timestamp, record
    end

    -- Pattern to extract parts from path: /logs/ACCOUNT_ID/vpcflowlogs/REGION/YEAR/MONTH/DAY/FILENAME
    local pattern = "/logs/([^/]+)/vpcflowlogs/([^/]+)/(%d+)/(%d+)/(%d+)/(.+)"
    
    local account_id, region, year, month, day, filename = path:match(pattern)
    
    if account_id then
        record.account_id = account_id
        record.region = region
        record.year = tonumber(year)
        record.month = tonumber(month)
        record.day = tonumber(day)
        record.filename = filename
        record.full_path = path
    end
    
    return 1, timestamp, record
end

return {extract_metadata = extract_metadata}