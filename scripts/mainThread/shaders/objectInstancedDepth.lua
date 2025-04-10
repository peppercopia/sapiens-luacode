
local shader = {
    vertPath = "objectInstancedDepth.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        pushConstantsVertSize = mj:sizeof("vec4")
    },
}

return shader