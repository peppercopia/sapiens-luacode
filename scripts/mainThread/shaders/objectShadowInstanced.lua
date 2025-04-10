
local shader = {
    vertPath = "objectShadowInstanced.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
        pushConstantsVertSize = mj:sizeof("vec4"),
    },
}

return shader