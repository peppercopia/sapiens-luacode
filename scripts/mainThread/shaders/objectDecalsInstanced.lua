
local shader = {
    vertPath = "objectDecalsInstanced.vert.spv",
    fragPath = "objectDecals.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "disabled",
        pushConstantsVertSize = mj:sizeof("vec4"),
    },
}

return shader