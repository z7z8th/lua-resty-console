---
--- Created by nickr.
--- DateTime: 1/8/19 9:19 PM
---

function string:split(sep)
    local tokens = {}
    local pattern = string.format("([^%s]+)", sep or ':')
    self:gsub(pattern, function(c) table.insert(tokens, c) end)
    return tokens
end

local function safe_match(str, re)
    local ok, res = pcall(function()
        return string.match(str, re)
    end)

    return ok and res
end

local function self_path()
    local path = debug.getinfo(1).source
    -- trim the leading @ and the last component (file part)
    return path:gsub('^"?@(.*)/[^/]+$', '%1')
end

return {
    self_path = self_path,
    safe_match = safe_match
}