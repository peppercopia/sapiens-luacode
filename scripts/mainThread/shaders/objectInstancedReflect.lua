
local shader = {
    vertPath = "objectInstanced.vert.spv",
    fragPath = "object.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "front",
        pushConstantsVertSize = mj:sizeof("vec4")
    },
}

return shader