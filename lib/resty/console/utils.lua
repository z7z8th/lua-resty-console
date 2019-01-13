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

return {
    safe_match = safe_match
}