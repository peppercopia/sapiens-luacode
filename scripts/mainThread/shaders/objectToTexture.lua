
local shader = {
    vertPath = "objectToTexture.vert.spv",
    fragPath = "objectToTexture.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
    },
}

return shader