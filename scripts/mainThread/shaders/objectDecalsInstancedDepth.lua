
local shader = {
    vertPath = "objectDecalsInstancedDepth.vert.spv",
    fragPath = "objectDecalsDepth.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        pushConstantsVertSize = mj:sizeof("vec4"),
        alphaToCoverage = true,
    },
}

return shader