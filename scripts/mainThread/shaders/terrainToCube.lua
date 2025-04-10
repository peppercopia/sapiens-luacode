
local shader = {
    vertPath = "terrainToCube.vert.spv",
    fragPath = "terrain.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader