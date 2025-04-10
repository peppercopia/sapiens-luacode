
local shader = {
    vertPath = "objectToTextureBonedDecal.vert.spv",
    fragPath = "objectToTextureDecal.frag.spv",
    options = {
        --blendMode = "disabled",
        --blendMode = "premultiplied",
        --depth = "testAndMask",
        --cull = "disabled",
        
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
       -- pushConstantsVertSize = mj:sizeof("vec4"),
        --alphaToCoverage = true,
    },
}

return shader