
local shader = {
    vertPath = "vrPointer.vert.spv",
    fragPath = "vrPointer.frag.spv",
    options = {
        blendMode = "additive",
        depth = "disabled",
        cull = "disabled",
        topology = "lines",
        lineWidth = 2.0,
    },
}

return shader