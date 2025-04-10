
local shader = {
    uniforms = {
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG"
        },
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG"
        },
    },
    fragPaths = {
        "atmo/copyIrradiance.frag"
    }
}

local atmoCommon = mjrequire "mainThread/shaders/atmo/atmoCommon"

return atmoCommon:combine(shader)