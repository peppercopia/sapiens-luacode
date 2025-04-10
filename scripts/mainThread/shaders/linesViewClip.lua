
local shader = {
    vertPath = "linesViewClip.vert.spv",
    fragPath = "linesViewClip.frag.spv",
    options = {
        blendMode = "additive",
        depth = "disabled",
        cull = "disabled",
        topology = "lines",
    },
}

return shader