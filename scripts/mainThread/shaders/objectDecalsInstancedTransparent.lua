
local shader = {
    vertPath = "objectDecalsInstanced.vert.spv",
    fragPath = "objectDecalsTransparent.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        pushConstantsVertSize = mj:sizeof("vec4"),
        alphaToCoverage = true,
    },
}

return shader