
local shader = {
    vertPath = "terrain.vert.spv",
    fragPath = "terrain.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMask",
        cull = "front",
    },
}

return shader