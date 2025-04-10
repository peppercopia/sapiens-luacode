
local shader = {
    vertPath = "objectToTextureDecal.vert.spv",
    fragPath = "objectToTextureDecal.frag.spv",
    options = {
        --blendMode = "disabled",
        --blendMode = "nonPremultiplied",
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
        --cull = "back",
       -- pushConstantsVertSize = mj:sizeof("vec4"),
        --alphaToCoverage = true,
    },
}

return shader