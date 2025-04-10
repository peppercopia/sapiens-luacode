
local shader = {
    vertPath = "vrPoint.vert.spv",
    fragPath = "vrPoint.frag.spv",
    options = {
        blendMode = "additive",
        depth = "disabled",
        cull = "disabled",
        topology = "points",
    },
}

return shader