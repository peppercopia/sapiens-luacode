
local shader = {
    vertPath = "globeViewRiver.vert.spv",
    fragPath = "globeViewRiver.frag.spv",
    options = {
        depth = "testOnly",
        cull = "disabled",
        topology = "lines",
        --lineWidth = 1.0,
        alphaToCoverage = true,
    },
}

return shader