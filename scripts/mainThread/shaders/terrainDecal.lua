
local shader = {
    vertPath = "terrainDecal.vert.spv",
    fragPath = "terrainDecal.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "disabled",
        --alphaToCoverage = true,
    },
}

return shader