
local shader = {
    uniforms = {
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG"
        },
    },
    fragPaths = {
        "atmo/irradiance1.frag"
    }
}

local atmoCommon = mjrequire "mainThread/shaders/atmo/atmoCommon"

return atmoCommon:combine(shader)