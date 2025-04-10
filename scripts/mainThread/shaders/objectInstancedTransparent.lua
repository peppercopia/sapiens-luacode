
local shader = {
    vertPath = "objectInstanced.vert.spv",
    fragPath = "objectTransparent.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
        pushConstantsVertSize = mj:sizeof("vec4"),
        alphaToCoverage = true,
    },
}

return shader