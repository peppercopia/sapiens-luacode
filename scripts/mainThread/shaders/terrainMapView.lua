
local shader = {
    vertPath = "terrainMapView.vert.spv",
    fragPath = "terrainMapView.frag.spv",
    options = {
        blendMode = "premultiplied",
        depth = "testOnly",
        cull = "disabled",
    },
}

return shader