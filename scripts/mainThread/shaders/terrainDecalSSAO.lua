
local shader = {
    vertPath = "terrainDecalSSAO.vert.spv",
    fragPath = "terrainDecalSSAO.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
    },
}

return shader