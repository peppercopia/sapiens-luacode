
local shader = {
    vertPath = "terrainToCubeLow.vert.spv",
    fragPath = "terrainLow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader