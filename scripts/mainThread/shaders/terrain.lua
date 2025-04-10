
local shader = {
    vertPath = "terrain.vert.spv",
    fragPath = "terrain.frag.spv",
    options = {
        blendMode = "disabled",
        depth = "testAndMaskEqual",
        cull = "back",
    },
}

return shader