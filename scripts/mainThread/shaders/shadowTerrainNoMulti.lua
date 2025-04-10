
local shader = {
    vertPath = "shadowTerrainNoMulti.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader