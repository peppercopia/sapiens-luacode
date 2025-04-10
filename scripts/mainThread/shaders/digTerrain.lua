
local shader = {
    vertPath = "digTerrain.vert.spv",
    fragPath = "digTerrain.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "back",
    },
}

return shader