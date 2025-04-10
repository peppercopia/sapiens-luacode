
local shader = {
    vertPath = "digTerrain.vert.spv",
    fragPath = "clearTerrain.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "back",
    },
}

return shader