function add_delay(tag, timestamp, record)
    -- Sleep for 50ms per record
    os.execute("sleep 0.05") 
    return 1, timestamp, record
end