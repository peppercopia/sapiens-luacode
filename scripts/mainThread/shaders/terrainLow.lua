
local shader = {
    vertPath = "terrainLow.vert.spv",
    fragPath = "terrainLow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "back",
    },
}

return shader