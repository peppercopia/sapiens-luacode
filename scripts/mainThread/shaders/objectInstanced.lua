
local shader = {
    vertPath = "objectInstanced.vert.spv",
    fragPath = "object.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "disabled",
        pushConstantsVertSize = mj:sizeof("vec4")
    },
}

return shader