
local shader = {
    vertPath = "linesView.vert.spv",
    fragPath = "linesView.frag.spv",
    options = {
        blendMode = "additive",
        depth = "disabled",
        cull = "disabled",
        topology = "lines",
    },
}

return shader