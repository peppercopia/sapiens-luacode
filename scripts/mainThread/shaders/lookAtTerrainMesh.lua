
local shader = {
    vertPath = "lookAtTerrainMesh.vert.spv",
    fragPath = "lookAtTerrainMesh.frag.spv",
    options = {
        blendMode = "subtractive",
        depth = "disabled",
        cull = "disabled",
        topology = "lines",
        lineWidth = 2.0,
        --alphaToCoverage = true,
    },
}

return shader