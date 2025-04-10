
local shader = {
    vertPath = "objectToTextureBoned.vert.spv",
    fragPath = "objectToTexture.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
    },
}

return shader