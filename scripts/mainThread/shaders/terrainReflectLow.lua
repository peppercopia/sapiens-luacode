
local shader = {
    vertPath = "terrainLow.vert.spv",
    fragPath = "terrainLow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "front",
    },
}

return shader