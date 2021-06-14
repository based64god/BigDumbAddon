local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function has(tbl, val)
    for index, value in ipairs(tbl) do
        if value == val then
            return true
        end
    end
    return false
end