---
--- Created by nickr.
--- DateTime: 1/8/19 9:19 PM
---


local function safe_match(str, re)
    local ok, res = pcall(function()
        return string.match(str, re)
    end)

    return ok and res
end

function string:split(sep)
    local fields
    sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

return {
    safe_match = safe_match
}