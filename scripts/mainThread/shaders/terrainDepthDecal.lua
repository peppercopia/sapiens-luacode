
local shader = {
    vertPath = "terrainDepthDecal.vert.spv",
    fragPath = "terrainDepthDecal.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "disabled",
        alphaToCoverage = true,
    },
}

return shader