
local shader = {
    uniforms = {
        {
            type = "UNIFORM_BUFFER",
            stage = "FRAG"
        },
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG"
        },
    },
    fragPaths = {
        "atmo/inscatterMie.frag"
    }
}

local atmoCommon = mjrequire "mainThread/shaders/atmo/atmoCommon"

return atmoCommon:combine(shader)