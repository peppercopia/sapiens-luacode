
local shader = {
    uniforms = {
        {
            type = "UNIFORM_BUFFER",
            stage = "FRAG"
        },
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG",
            count = 32
        },
        {
            type = "COMBINED_IMAGE_SAMPLER",
            stage = "FRAG",
            count = 32
        },
    },
    fragPaths = {
        "atmo/irradianceN.frag"
    }
}

local atmoCommon = mjrequire "mainThread/shaders/atmo/atmoCommon"

return atmoCommon:combine(shader)