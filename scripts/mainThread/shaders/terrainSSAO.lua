
local shader = {
    vertPath = "terrainSSAO.vert.spv",
    fragPath = "shadow.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "back",
    },
}

return shader