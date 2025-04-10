
local shader = {
    vertPath = "buildTerrain.vert.spv",
    fragPath = "buildTerrain.frag.spv",
    options = {
        blendMode = "additive",
        depth = "testOnly",
        cull = "back",
    },
}

return shader