
local shader = {
    vertPath = "exposure.vert.spv",
    fragPath = "exposure.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "disabled",
        cull = "disabled",
        --pushConstantsFragSize = mj:sizeof("vec4"),
    },
}

return shader