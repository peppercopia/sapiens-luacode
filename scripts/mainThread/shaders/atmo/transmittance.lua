
local shader = {
    fragPaths = {
        "atmo/transmittance.frag"
    }
}

local atmoCommon = mjrequire "mainThread/shaders/atmo/atmoCommon"

return atmoCommon:combine(shader)